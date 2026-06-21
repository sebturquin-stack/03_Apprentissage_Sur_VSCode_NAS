#!/bin/sh
set -eu

VM_NAME="${VM_NAME:-Mint-Infra-Server}"
VM_SLUG="mint-infra-server"
BACKUP_DIR="${BACKUP_DIR:-}"
LOG_FILE="${LOG_FILE:-/var/log/vm_backup_qnap.log}"
LOCK_FILE="${LOCK_FILE:-/var/lock/vm_backup_qnap.lock}"
STATUS_DIR="${STATUS_DIR:-/var/lib/vm_backup_qnap}"
LAST_RUN_FILE="${LAST_RUN_FILE:-$STATUS_DIR/last_run.status}"
LAST_SUCCESS_FILE="${LAST_SUCCESS_FILE:-$STATUS_DIR/last_success.status}"
LOG_MAX_BYTES="${LOG_MAX_BYTES:-10485760}"
LOG_KEEP_FILES="${LOG_KEEP_FILES:-5}"
MIN_FREE_BYTES="${MIN_FREE_BYTES:-10737418240}"
KEEP_LAST="${KEEP_LAST:-7}"
EXPORT_FORMAT="${EXPORT_FORMAT:-qcow2}"
VIRSH="${VIRSH:-/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/virsh}"
QEMU_IMG="${QEMU_IMG:-/share/CACHEDEV1_DATA/.qpkg/QKVM/usr/bin/qemu-img}"
ENABLE_HOT_SNAPSHOT="${ENABLE_HOT_SNAPSHOT:-no}"
RESOLVED_VM_NAME=""
RUN_TS="$(date '+%F_%H-%M-%S')"
RUN_EPOCH="$(date '+%s')"
SUCCESS_RUN=0
LAST_DISK_OUT=""
LAST_XML_OUT=""

umask 027

rotate_log_if_needed() {
  [ -f "$LOG_FILE" ] || return 0
  size="$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)"
  case "$size" in
    ''|*[!0-9]*) size=0 ;;
  esac
  if [ "$size" -lt "$LOG_MAX_BYTES" ]; then
    return 0
  fi

  i="$LOG_KEEP_FILES"
  while [ "$i" -ge 1 ]; do
    if [ -f "$LOG_FILE.$i" ]; then
      if [ "$i" -eq "$LOG_KEEP_FILES" ]; then
        rm -f "$LOG_FILE.$i"
      else
        next=$((i + 1))
        mv "$LOG_FILE.$i" "$LOG_FILE.$next"
      fi
    fi
    i=$((i - 1))
  done
  mv "$LOG_FILE" "$LOG_FILE.1"
}

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOCK_FILE")" "$STATUS_DIR"
touch "$LOG_FILE"
rotate_log_if_needed

log() {
  level="$1"
  shift
  printf '%s [%s] %s\n' "$(date '+%F %T')" "$level" "$*" >> "$LOG_FILE"
}

die() {
  log "ERROR" "$*"
  exit 1
}

cleanup() {
  rc="$?"
  if [ "$SUCCESS_RUN" -eq 1 ]; then
    printf 'status=success\nrun_ts=%s\nrun_epoch=%s\nvm=%s\nresolved_vm=%s\nbackup_dir=%s\ndisk=%s\nxml=%s\n' \
      "$RUN_TS" "$RUN_EPOCH" "$VM_NAME" "$RESOLVED_VM_NAME" "$BACKUP_DIR" "$LAST_DISK_OUT" "$LAST_XML_OUT" > "$LAST_RUN_FILE"
    cp -f "$LAST_RUN_FILE" "$LAST_SUCCESS_FILE"
  elif [ "$rc" -ne 0 ]; then
    log "ERROR" "Sortie en echec (code=$rc)"
    printf 'status=failed\nrun_ts=%s\nrun_epoch=%s\nvm=%s\nresolved_vm=%s\nbackup_dir=%s\nexit_code=%s\n' \
      "$RUN_TS" "$RUN_EPOCH" "$VM_NAME" "$RESOLVED_VM_NAME" "$BACKUP_DIR" "$rc" > "$LAST_RUN_FILE"
  fi
  rm -f "$LOCK_FILE" 2>/dev/null || true
}
trap cleanup EXIT

[ "$(id -u)" -eq 0 ] || die "Execution root requise."

if [ -f "$LOCK_FILE" ]; then
  old_pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    log "WARN" "Sauvegarde deja en cours (pid=$old_pid), sortie sans blocage."
    exit 0
  fi
fi
printf '%s' "$$" > "$LOCK_FILE"

find_backup_dir() {
  if [ -n "$BACKUP_DIR" ]; then
    printf '%s\n' "$BACKUP_DIR"
    return
  fi

  for path in \
    /share/InfraData/03_Backups/02_Linux/01_Backups_VM \
    /share/CACHEDEV1_DATA/InfraData/03_Backups/02_Linux/01_Backups_VM \
    /share/MD0_DATA/InfraData/03_Backups/02_Linux/01_Backups_VM
  do
    if [ -d "$path" ] || mkdir -p "$path" 2>/dev/null; then
      printf '%s\n' "$path"
      return
    fi
  done

  die "Impossible de determiner BACKUP_DIR sur l'hote QNAP."
}

check_free_space() {
  avail="$(df -P "$BACKUP_DIR" | awk 'NR==2 {print $4}')"
  [ -n "$avail" ] || die "Impossible de lire l'espace libre sur $BACKUP_DIR"
  avail_bytes=$((avail * 1024))
  if [ "$avail_bytes" -lt "$MIN_FREE_BYTES" ]; then
    die "Espace insuffisant sur $BACKUP_DIR (${avail_bytes} bytes < ${MIN_FREE_BYTES})."
  fi
}

need_exec() {
  [ -x "$1" ] || die "Commande requise absente ou non executable: $1"
}

normalize_name() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]'
}

trim_vm_prefix() {
  printf '%s' "$1" | sed 's/^vm//'
}

sanitize_format() {
  case "$EXPORT_FORMAT" in
    qcow2|QCOW2) EXPORT_FORMAT="qcow2" ;;
    vdi|VDI) EXPORT_FORMAT="vdi" ;;
    *) die "EXPORT_FORMAT invalide: $EXPORT_FORMAT (attendu: qcow2|vdi)" ;;
  esac
}

resolve_vm_name() {
  if "$VIRSH" dominfo "$VM_NAME" >/dev/null 2>&1; then
    printf '%s\n' "$VM_NAME"
    return
  fi

  target_norm="$(trim_vm_prefix "$(normalize_name "$VM_NAME")")"
  for dom in $("$VIRSH" list --all --name | sed '/^$/d'); do
    xml="$("$VIRSH" dumpxml "$dom" 2>/dev/null || true)"
    qvs_name="$(printf '%s\n' "$xml" | grep '<qvs:name>' | head -n 1 | cut -d'>' -f2 | cut -d'<' -f1)"
    desc="$(printf '%s\n' "$xml" | grep '<description>' | head -n 1 | cut -d'>' -f2 | cut -d'<' -f1)"
    for candidate in "$dom" "$qvs_name" "$desc"; do
      [ -n "$candidate" ] || continue
      candidate_norm="$(trim_vm_prefix "$(normalize_name "$candidate")")"
      case "$candidate_norm" in
        *"$target_norm"*|"$target_norm"*)
          printf '%s\n' "$dom"
          return
          ;;
      esac
    done
  done

  return 1
}

maybe_snapshot() {
  ts="$1"
  if [ "$ENABLE_HOT_SNAPSHOT" != "yes" ]; then
    log "WARN" "Snapshot a chaud desactive (ENABLE_HOT_SNAPSHOT=no). Export best-effort poursuivi."
    return 0
  fi

  state="$("$VIRSH" domstate "$RESOLVED_VM_NAME" 2>/dev/null | tr -d '\r' || true)"
  if [ "$state" = "running" ]; then
    snap="pre-export-$ts"
    if "$VIRSH" snapshot-create-as --domain "$RESOLVED_VM_NAME" --name "$snap" --description "Pre-export snapshot $ts" --atomic --no-metadata >/dev/null 2>&1; then
      log "INFO" "Snapshot a chaud cree: $snap"
    else
      log "WARN" "Snapshot a chaud indisponible ou timeout. Export best-effort poursuivi."
    fi
  fi
}

find_source_disk() {
  "$VIRSH" domblklist "$RESOLVED_VM_NAME" --details | awk '
    $2=="disk" {
      line=$0
      sub(/^[[:space:]]*[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+/, "", line)
      print line
      exit
    }
  '
}

find_source_format() {
  "$VIRSH" dumpxml "$RESOLVED_VM_NAME" | awk "
    /<disk type='file' device='disk'>/ { in_disk=1 }
    in_disk && /<driver / {
      if (match(\$0, /type='[^']+'/)) {
        value=substr(\$0, RSTART + 6, RLENGTH - 7)
        print value
        exit
      }
    }
    in_disk && /<\\/disk>/ { in_disk=0 }
  "
}

export_disk_and_config() {
  ts="$RUN_TS"
  disk_out="$BACKUP_DIR/${VM_SLUG}_${ts}.${EXPORT_FORMAT}"
  cfg_out="$BACKUP_DIR/${VM_SLUG}_${ts}.xml"

  "$VIRSH" dominfo "$RESOLVED_VM_NAME" >/dev/null 2>&1 || die "VM introuvable via virsh: $VM_NAME"
  maybe_snapshot "$ts"

  src_disk="$(find_source_disk)"
  src_format="$(find_source_format)"
  [ -n "$src_disk" ] || die "Disque source introuvable pour $VM_NAME"
  [ -r "$src_disk" ] || die "Disque source non lisible: $src_disk"

  case "$EXPORT_FORMAT" in
    qcow2)
      if [ "$src_format" = "qcow2" ] || echo "$src_disk" | grep -qi '\.qcow2$'; then
        cp --sparse=always "$src_disk" "$disk_out"
      else
        "$QEMU_IMG" convert -O qcow2 "$src_disk" "$disk_out"
      fi
      ;;
    vdi)
      "$QEMU_IMG" convert -O vdi "$src_disk" "$disk_out"
      ;;
  esac

  "$VIRSH" dumpxml "$RESOLVED_VM_NAME" > "$cfg_out"
  LAST_DISK_OUT="$disk_out"
  LAST_XML_OUT="$cfg_out"
  log "INFO" "Export termine: $disk_out + $cfg_out"
}

rotate_backups() {
  old_list="$(ls -1t "$BACKUP_DIR"/${VM_SLUG}_*.qcow2 "$BACKUP_DIR"/${VM_SLUG}_*.vdi 2>/dev/null | awk 'NR>'"$KEEP_LAST"' {print $0}')"
  [ -n "$old_list" ] || return 0
  echo "$old_list" | while IFS= read -r file; do
    [ -f "$file" ] || continue
    base="$(basename "$file")"
    stamp="${base#${VM_SLUG}_}"
    stamp="${stamp%.qcow2}"
    stamp="${stamp%.vdi}"
    rm -f "$file" "$BACKUP_DIR/${VM_SLUG}_${stamp}.xml"
    log "INFO" "Rotation: suppression ${VM_SLUG}_${stamp}"
  done
}

BACKUP_DIR="$(find_backup_dir)"
mkdir -p "$BACKUP_DIR"

main() {
  log "INFO" "Debut sauvegarde QNAP hote pour VM: $VM_NAME"
  log "INFO" "run_ts=$RUN_TS"
  sanitize_format
  need_exec "$VIRSH"
  need_exec "$QEMU_IMG"
  check_free_space
  RESOLVED_VM_NAME="$(resolve_vm_name || true)"
  [ -n "$RESOLVED_VM_NAME" ] || die "VM introuvable via virsh: $VM_NAME"
  log "INFO" "VM resolue via virsh: $RESOLVED_VM_NAME"
  export_disk_and_config
  rotate_backups
  SUCCESS_RUN=1
  log "INFO" "Sauvegarde terminee avec succes."
}

main "$@"
