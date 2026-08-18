# Trace Forge

**Trace Forge** is Trace's high-performance coding-agent harness, built in Rust for complex, autonomous software engineering tasks.

Forge is designed to give coding agents a reliable execution environment with the tools, context, and control they need to work through real-world codebases.

## Quick Install

Run this command in your terminal (macOS / Linux):

```bash
curl -fsSL https://raw.githubusercontent.com/tracedevtools/Forge-release/main/install.sh | bash
```

After running the install command:
1. Reload your Trace Chrome Extension at `chrome://extensions`
2. Click **Connect** in the extension — the native Rust agent launches automatically!

## Why Forge?

Modern coding agents are only as capable as the harness around the model.

Trace Forge focuses on:

- **Complex tasks** — built for multi-step software engineering workflows
- **Long-running execution** — designed to let agents work through tasks without constant intervention
- **High performance** — native Rust execution with low runtime overhead
- **Reliable tool execution** — structured interaction with files, terminals, processes, and development environments
- **Large codebases** — designed for exploration, reasoning, modification, and verification across existing projects
- **Model agnostic** — the harness is independent of the underlying LLM

## Architecture

Forge sits between the model and the development environment:

```text
┌─────────────────────┐
│        Model        │
│ Claude / GPT / etc. │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│    Trace Forge      │
│  Coding Agent       │
│      Harness        │
└──────────┬──────────┘
           │
     ┌─────┼─────┐
     ▼     ▼     ▼
   Files  Shell  Tools
           │
           ▼
      Codebase
```

---

**Built by [@mrgear111](https://github.com/mrgear111)**
