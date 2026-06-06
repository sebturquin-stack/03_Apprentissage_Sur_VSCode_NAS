import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const NETDATA_BASE_URL = (process.env.NETDATA_BASE_URL || "http://localhost:19999").replace(/\/$/, "");
const NETDATA_TIMEOUT_MS = Number.parseInt(process.env.NETDATA_TIMEOUT_MS || "5000", 10);

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
    await server.connect(transport);
}

main().catch((error) => {
    const details = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
    process.stderr.write(`[netdata-mcp] Fatal error: ${details}\n`);
    process.exit(1);
});
