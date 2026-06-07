
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// --- Healthcheck handler ---
if (process.argv.includes("--healthcheck")) {
    console.log("OK");
    process.exit(0);
}

globalThis.DEBUG = process.argv.includes("--debug");
const DEBUG = globalThis.DEBUG === true;
const NETDATA_BASE_URL = (process.env.NETDATA_BASE_URL || "http://localhost:19999").replace(/\/$/, "");
const NETDATA_TIMEOUT_MS = Number.parseInt(process.env.NETDATA_TIMEOUT_MS || "5000", 10);

function debugLog(message, details) {
    if (!DEBUG) {
        return;
    }

    const suffix = details === undefined ? "" : ` ${typeof details === "string" ? details : JSON.stringify(details)}`;
    process.stderr.write(`[netdata-mcp][debug] ${message}${suffix}\n`);
}

function formatError(error) {
    if (error instanceof Error) {
        return DEBUG && error.stack ? error.stack : `${error.name}: ${error.message}`;
    }

    return String(error);
}

function logError(context, error) {
    process.stderr.write(`[netdata-mcp] ${context}: ${formatError(error)}\n`);
}

function keepProcessAlive() {
    if (globalThis.__netdataMcpKeepAliveTimer) {
        return;
    }

    if (DEBUG) {
        globalThis.__netdataMcpKeepAliveTimer = setInterval(() => {
            debugLog("debug keepalive tick");
        }, 60_000);
        return;
    }

    // Keep the container process alive to avoid restart loops on transient startup issues.
    globalThis.__netdataMcpKeepAliveTimer = setInterval(() => { }, 60_000);
}

if (DEBUG) {
    process.stderr.write("MCP DEBUG MODE ACTIVE\n");
    debugLog("script starting", {
        argv: process.argv.slice(2),
        pid: process.pid,
        nodeVersion: process.version
    });
    process.stdin.on("data", (chunk) => {
        const preview = chunk.toString("utf8", 0, Math.min(chunk.length, 240));
        debugLog("received STDIO message chunk", {
            bytes: chunk.length,
            preview
        });
    });
    process.stdin.on("end", () => {
        debugLog("STDIO transport ended");
    });
    process.stdin.on("close", () => {
        debugLog("STDIO transport closed");
        keepProcessAlive();
    });
    process.stdin.on("error", (error) => {
        logError("STDIO transport error", error);
        keepProcessAlive();
    });
}

process.on("uncaughtException", (error) => {
    logError("uncaught exception", error);
    keepProcessAlive();
    if (!DEBUG) {
        process.exit(1);
    }
});

process.on("unhandledRejection", (reason) => {
    logError("unhandled rejection", reason);
    keepProcessAlive();
    if (!DEBUG) {
        process.exit(1);
    }
});

process.on("exit", (code) => {
    debugLog("process exiting", { code });
});

function safeParseJson(text) {
    try {
        return JSON.parse(text);
    } catch {
        return text;
    }
}

function formatToolResponse(payload) {
    return {
        content: [
            {
                type: "text",
                text: JSON.stringify(payload, null, 2)
            }
        ]
    };
}

async function netdataGet(path, query = {}) {
    const url = new URL(`${NETDATA_BASE_URL}${path}`);
    for (const [key, value] of Object.entries(query)) {
        if (value !== undefined && value !== null) {
            url.searchParams.set(key, String(value));
        }
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), NETDATA_TIMEOUT_MS);

    try {
        const response = await fetch(url, {
            method: "GET",
            headers: {
                Accept: "application/json"
            },
            signal: controller.signal
        });

        const rawBody = await response.text();
        const body = safeParseJson(rawBody);

        if (!response.ok) {
            return {
                ok: false,
                error: {
                    type: "http_error",
                    message: `Netdata returned HTTP ${response.status}`,
                    status: response.status,
                    statusText: response.statusText,
                    url: url.toString(),
                    body
                }
            };
        }

        return {
            ok: true,
            url: url.toString(),
            data: body
        };
    } catch (error) {
        if (error?.name === "AbortError") {
            return {
                ok: false,
                error: {
                    type: "timeout",
                    message: `Netdata request timed out after ${NETDATA_TIMEOUT_MS} ms`,
                    url: url.toString()
                }
            };
        }

        return {
            ok: false,
            error: {
                type: "network_error",
                message: error instanceof Error ? error.message : String(error),
                url: url.toString()
            }
        };
    } finally {
        clearTimeout(timeoutId);
    }
}

async function getChartSnapshot(chart) {
    return netdataGet("/api/v1/data", {
        chart,
        after: -60,
        points: 1,
        format: "json"
    });
}

debugLog("creating MCP server");
const server = new McpServer({
    name: "netdata-mcp",
    version: "1.0.0"
});

server.tool(
    "get_netdata_info",
    "Returns general information about the Netdata Agent via /api/v1/info",
    {},
    async () => {
        const result = await netdataGet("/api/v1/info");
        return formatToolResponse({
            tool: "get_netdata_info",
            netdataBaseUrl: NETDATA_BASE_URL,
            timeoutMs: NETDATA_TIMEOUT_MS,
            ...result
        });
    }
);

server.tool(
    "get_cpu_snapshot",
    "Returns a recent CPU snapshot via /api/v1/data for chart system.cpu",
    {},
    async () => {
        const result = await getChartSnapshot("system.cpu");
        return formatToolResponse({
            tool: "get_cpu_snapshot",
            chart: "system.cpu",
            ...result
        });
    }
);

server.tool(
    "get_ram_snapshot",
    "Returns a recent RAM snapshot via /api/v1/data for chart system.ram",
    {},
    async () => {
        const result = await getChartSnapshot("system.ram");
        return formatToolResponse({
            tool: "get_ram_snapshot",
            chart: "system.ram",
            ...result
        });
    }
);

server.tool(
    "get_disk_snapshot",
    "Returns a recent disk snapshot via /api/v1/data for chart system.io",
    {
        chart: z.string().default("system.io").optional().describe("Chart name to query, default: system.io")
    },
    async ({ chart = "system.io" }) => {
        const result = await getChartSnapshot(chart);
        return formatToolResponse({
            tool: "get_disk_snapshot",
            chart,
            ...result
        });
    }
);

async function main() {
    const transport = new StdioServerTransport();
    debugLog("creating STDIO transport");
    keepProcessAlive();

    debugLog("opening transport");
    await server.connect(transport);
    debugLog("transport opened");
}

main()
    .then(() => {
        debugLog("main() resolved");
    })
    .catch((error) => {
        logError("fatal error", error);
        keepProcessAlive();

        if (!DEBUG) {
            process.exit(1);
        }
    });
