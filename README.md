# trycookcli

CLI and SDK for the [TryCook](https://trycook.ai) platform. Discover, inspect, and execute tools from your terminal or code.

> **Repository policy.** This repository is a **release/install repo only**. The TryCook CLI source of truth lives in a private monorepo and is **not** mirrored here. Binary distribution is exclusively via [GitHub Releases](https://github.com/caio-systems/trycookcli/releases). There is no automated subtree sync, and one will not be added — public source, if ever desired, lands as an explicit, curated PR. See [`CONTRIBUTING.md`](./CONTRIBUTING.md) and [`RELEASING.md`](./RELEASING.md).

## Install

```bash
npm install -g trycookcli
```

## CLI

```bash
# Authenticate
trycook auth

# List available tools
trycook tools

# Search tools
trycook tools search "video review"

# Get tool schema
trycook tool info list_video_reviews

# Call a tool
trycook tool call list_video_reviews '{"status":"approved","limit":5}'
```

## SDK

```typescript
import { TryCookClient } from 'trycookcli/client'

const client = new TryCookClient('https://api.trycook.ai')
const result = await client.callTool('list_video_reviews', { limit: 10 })
```

### Virtual CLI (for AI agents)

Three meta-tools that replace 100+ individual tool registrations. Agents discover tools on demand.

```typescript
import { createVirtualCLITools } from 'trycookcli/virtual-cli'

const tools = createVirtualCLITools({
  apiUrl: 'https://api.trycook.ai',
  sandboxKey: process.env.SANDBOX_KEY,
})

// tools.trycook_search_tools  — discover available tools
// tools.trycook_tool_schema   — get input schema for a tool
// tools.trycook_call_tool     — execute any tool by name
```

## MCP Server

Connect any MCP-compatible client (Claude Code, Claude Desktop, Cursor) to TryCook:

```json
{
  "mcpServers": {
    "trycook": {
      "url": "https://mcp.trycook.ai/mcp"
    }
  }
}
```

OAuth authentication is handled automatically on first connection.

## Claude Code Plugin

When installed in a project, Claude Code auto-discovers TryCook tools via the bundled `.claude-plugin` config.

## Documentation

Full docs at [docs.trycook.ai](https://docs.trycook.ai)

## License

Proprietary. See [LICENSE](./LICENSE) for details.
