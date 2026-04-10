---
name: zed-editor
description: "Zed Editor extensions - Rust/Wasm plugins, LSP servers, Tree-sitter grammars, themes, MCP servers, slash commands, debug adapters"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - zed
    - editor
    - extension
    - rust
    - wasm
    - tree-sitter
    - lsp
    - plugin
---

# Zed Editor Extensions

Build extensions for the [Zed](https://zed.dev) editor — high-performance, multiplayer code editor built in Rust.

Extensions are **Rust crates compiled to WebAssembly** that run in a sandboxed Wasmtime environment. They can provide languages, themes, debuggers, snippets, MCP servers, and AI slash commands.

## Overview

**What extensions can provide:**
- Language support (Tree-sitter grammars + LSP servers)
- Color themes and icon themes
- Snippet collections
- Debug adapters (DAP)
- MCP context servers (for AI assistant)
- Slash commands (for AI assistant)
- Agent servers (ACP)

**What extensions CANNOT do:**
- Create custom UI panels or windows (no GPUI access)
- Modify Zed's core UI behavior
- Arbitrary filesystem access (restricted by capabilities)
- Run system commands without user-granted capability

---

## Directory Structure

```
my-extension/
├── extension.toml          # Required manifest
├── Cargo.toml              # Required for Rust extensions (cdylib)
├── src/
│   └── lib.rs              # Extension implementation
├── languages/
│   └── my-language/
│       ├── config.toml     # Language metadata
│       ├── highlights.scm  # Syntax highlighting
│       ├── brackets.scm    # Bracket matching
│       ├── outline.scm     # Code outline
│       ├── indents.scm     # Auto-indentation
│       ├── injections.scm  # Language injections
│       ├── overrides.scm   # Editor behavior overrides
│       ├── textobjects.scm # Text objects (Vim)
│       ├── redactions.scm  # Screen share redaction
│       ├── runnables.scm   # Runnable code detection
│       └── semantic_token_rules.json  # LSP semantic tokens
├── themes/
│   └── my-theme.json       # Theme definitions
├── icon-themes/
│   └── my-icons.json       # Icon theme definitions
└── snippets/
    └── snippets.json        # Snippet definitions
```

---

## Extension Manifest (extension.toml)

```toml
id = "my-extension"
name = "My Extension"
version = "0.1.0"
schema_version = 1
authors = ["Your Name <you@example.com>"]
description = "Provides support for My Language"
repository = "https://github.com/you/my-zed-extension"

# Tree-sitter grammars
[grammars.my-language]
repository = "https://github.com/tree-sitter/tree-sitter-my-language"
rev = "abc123def456"

# For local development, use file:// URL
# [grammars.my-language]
# repository = "file:///path/to/tree-sitter-my-language"

# Language servers
[language_servers.my-lsp]
name = "My Language Server"
languages = ["My Language"]

# Multi-language server with LSP ID mapping
# [language_servers.my-lsp]
# name = "Whatever LSP"
# languages = ["JavaScript", "HTML", "CSS"]
#
# [language_servers.my-lsp.language_ids]
# "JavaScript" = "javascript"
# "TSX" = "typescriptreact"
# "HTML" = "html"

# Debug adapters
[debug_adapters.my-dap]
schema_path = "debug_adapter_schemas/my-dap.json"

# MCP context servers
[context_servers.my-mcp]

# Agent servers
[agent_servers.my-agent]
name = "My AI Agent"
icon = "icon/agent.svg"

[agent_servers.my-agent.env]
AGENT_LOG_LEVEL = "info"

[agent_servers.my-agent.targets.darwin-aarch64]
archive = "https://github.com/owner/repo/releases/download/v1.0.0/agent-darwin-arm64.tar.gz"
cmd = "./agent"
args = ["--serve"]
sha256 = "abc123..."

[agent_servers.my-agent.targets.linux-x86_64]
archive = "https://github.com/owner/repo/releases/download/v1.0.0/agent-linux-x64.tar.gz"
cmd = "./agent"
args = ["--serve"]
```

---

## Rust Extension Setup

### Cargo.toml

```toml
[package]
name = "my-extension"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
zed_extension_api = "0.1.0"  # Use latest from crates.io
serde = "1.0"
serde_json = "1.0"
```

> **Important**: Use the latest `zed_extension_api` version from [crates.io](https://crates.io/crates/zed_extension_api). Check [compatible Zed versions](https://github.com/zed-industries/zed/blob/main/crates/extension_api#compatible-zed-versions).

### src/lib.rs — Basic Extension

```rust
use zed_extension_api as zed;

struct MyExtension;

impl zed::Extension for MyExtension {
    fn new() -> Self {
        Self
    }
}

zed::register_extension!(MyExtension);
```

---

## Language Server (LSP) Integration

### Configuration in extension.toml

```toml
[language_servers.my-language-server]
name = "My Language LSP"
languages = ["My Language"]
```

### Implementation

```rust
use zed_extension_api as zed;

struct MyExtension {
    cached_binary_path: Option<String>,
}

impl zed::Extension for MyExtension {
    fn new() -> Self {
        Self { cached_binary_path: None }
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        // Option 1: Use binary from PATH
        let path = worktree
            .which("my-language-server")
            .ok_or_else(|| "my-language-server not found in PATH".to_string())?;

        Ok(zed::Command {
            command: path,
            args: vec!["--stdio".to_string()],
            env: worktree.shell_env(),
        })
    }
}
```

### Downloading Language Server from GitHub

```rust
fn language_server_command(
    &mut self,
    _language_server_id: &zed::LanguageServerId,
    worktree: &zed::Worktree,
) -> zed::Result<zed::Command> {
    let binary_path = format!(
        "{}/my-language-server-{}",
        worktree.root_path(),
        std::env::consts::OS
    );

    if !std::path::Path::new(&binary_path).exists() {
        let release = zed::latest_github_release(
            "owner/my-language-server",
            zed::GithubReleaseOptions { require_assets: true },
        )?;

        let (os, arch) = zed::current_platform();
        let asset_name = format!("server-{}-{}.tar.gz", os, arch);

        let asset = release.assets
            .iter()
            .find(|a| a.name.contains(&asset_name))
            .ok_or_else(|| format!("No release asset matching '{}'", asset_name))?;

        zed::download_file(&asset.browser_download_url, &binary_path)?;
        zed::make_file_executable(&binary_path)?;
    }

    Ok(zed::Command {
        command: binary_path,
        args: vec!["--stdio".to_string()],
        env: worktree.shell_env(),
    })
}
```

### Using npm Packages

```rust
fn language_server_command(
    &mut self,
    _language_server_id: &zed::LanguageServerId,
    worktree: &zed::Worktree,
) -> zed::Result<zed::Command> {
    if zed::npm_package_installed_version("my-language-server").is_none() {
        zed::npm_install_package("my-language-server")?;
    }

    Ok(zed::Command {
        command: format!("{}/node_modules/.bin/my-language-server",
            zed::node_binary_path()),
        args: vec!["--stdio".to_string()],
        env: worktree.shell_env(),
    })
}
```

### LSP Initialization Options

```rust
fn language_server_initialization_options(
    &mut self,
    _language_server_id: &zed::LanguageServerId,
    _worktree: &zed::Worktree,
) -> zed::Result<Option<serde_json::Value>> {
    Ok(Some(serde_json::json!({
        "settings": {
            "enableFormatting": true,
            "lint": { "enable": true }
        }
    })))
}
```

### Custom Completion Labels

```rust
fn label_for_completion(
    &self,
    _language_server_id: &zed::LanguageServerId,
    completion: zed::lsp::Completion,
) -> Option<zed::CodeLabel> {
    Some(zed::CodeLabel {
        text: completion.label.clone(),
        filter_range: 0..completion.label.len(),
        display_range: 0..completion.label.len(),
        syntax_highlights: vec![],
    })
}
```

---

## Language Support (Tree-sitter)

### Language config.toml

Place in `languages/my-language/config.toml`:

```toml
name = "My Language"
grammar = "my-language"               # Must match grammar name in extension.toml
path_suffixes = ["myl", "mylang"]     # File extensions
line_comments = ["// ", "# "]          # Line comment prefixes
block_comments = [{ start = "/*", end = "*/" }]
tab_size = 4
hard_tabs = false
first_line_pattern = "^#!.*myl"       # Shebang detection
word_characters = ["#", "$", "-"]     # Non-alpha chars that are part of words

# Bracket auto-closing configuration
brackets = [
    { start = "{", end = "}", close = true, newline = true },
    { start = "(", end = ")", close = true, newline = true },
    { start = "[", end = "]", close = true, newline = true },
    { start = "\"", end = "\"", close = true, newline = false, not_in = ["string"] },
]

# Scope-specific overrides
[overrides.string]
completion_query_characters = ["-", "."]
```

### Tree-sitter Query Files

All `.scm` files go in `languages/my-language/`.

#### highlights.scm — Syntax Highlighting

```scheme
(string) @string
(comment) @comment
(number) @number
(keyword) @keyword
(function name: (identifier) @function)
(type_identifier) @type
(identifier) @variable
(property_identifier) @property
(operator) @operator
(constant) @constant
(boolean) @boolean
```

**Supported captures:**
| Capture | Description |
|---------|-------------|
| `@string` | String literals |
| `@string.escape` | Escaped characters |
| `@string.regex` | Regular expressions |
| `@string.special` | Special strings |
| `@comment` | Comments |
| `@comment.doc` | Doc comments |
| `@keyword` | Keywords |
| `@number` | Numeric values |
| `@boolean` | Boolean values |
| `@function` | Functions |
| `@type` | Types |
| `@type.builtin` | Built-in types |
| `@variable` | Variables |
| `@variable.special` | Special variables |
| `@variable.parameter` | Parameters |
| `@property` | Properties |
| `@operator` | Operators |
| `@constant` | Constants |
| `@constant.builtin` | Built-in constants |
| `@constructor` | Constructors |
| `@attribute` | Attributes |
| `@tag` | Tags |
| `@label` | Labels |
| `@punctuation` | Punctuation |
| `@punctuation.bracket` | Brackets |
| `@punctuation.delimiter` | Delimiters |
| `@preproc` | Preprocessor directives |
| `@embedded` | Embedded content |
| `@enum` | Enumerations |
| `@variant` | Variants |

**Fallback captures:** Multiple captures on same node define fallback highlights:
```scheme
(type_identifier) @type @variable
```
Zed resolves right-to-left: tries `@variable` first, falls back to `@type`.

#### brackets.scm — Bracket Matching

```scheme
("{" @open "}" @close)
("[" @open "]" @close)
("(" @open ")" @close)
("\"" @open "\"" @close) (#set! rainbow.exclude)  ; Exclude from rainbow brackets
```

#### outline.scm — Code Outline

```scheme
(function_definition name: (identifier) @name) @item
(class_definition name: (identifier) @name) @item
(method_definition name: (identifier) @name) @item
```

Captures: `@name` (item name), `@item` (entire item), `@context` (context info), `@annotation` (decorators, doc comments).

#### indents.scm — Auto-Indentation

```scheme
(array "]" @end) @indent
(object "}" @end) @indent
(function_definition body: (block "{" @indent))
```

#### injections.scm — Language Injections

```scheme
(fenced_code_block
    (info_string (language) @injection.language)
    (code_fence_content) @injection.content)

((string_content) @injection.content
    (#set! injection.language "sql"))
```

#### textobjects.scm — Vim Text Objects

```scheme
(method_definition
    body: (_
        "{"
        (_)* @function.inside
        "}")) @function.around

(class_definition
    body: (_
        "{"
        (_)* @class.inside
        "}")) @class.around

(comment)+ @comment.around
```

Captures: `@function.around`, `@function.inside`, `@class.around`, `@class.inside`, `@comment.around`, `@comment.inside`.

#### redactions.scm — Screen Share Privacy

```scheme
(pair value: (string) @redact)
(pair value: (number) @redact)
(password_field) @redact
```

#### runnables.scm — Runnable Code Detection

```scheme
(
    (document
        (object
            (pair
                key: (string (string_content) @_name
                    (#eq? @_name "scripts"))
                value: (object
                    (pair
                        key: (string (string_content) @run))
                    )
                )
            )
        )
    )
)
```

Extra captures (except `_` prefixed) become `ZED_CUSTOM_<capture_name>` env vars.

---

## MCP Server Extensions

### Registration

```toml
[context_servers.my-mcp]
```

### Implementation

```rust
fn context_server_command(
    &mut self,
    _context_server_id: &zed::ContextServerId,
    _project: &zed::Project,
) -> zed::Result<zed::Command> {
    Ok(zed::Command {
        command: "my-mcp-server".to_string(),
        args: vec!["--stdio".to_string()],
        env: std::env::vars().collect(),
    })
}
```

---

## Slash Commands (AI Assistant)

### Registration in extension.toml

```toml
[[slash_commands.my-command]]
description = "Does something useful"
requires_argument = true
```

### Implementation

```rust
fn run_slash_command(
    &self,
    command: zed::SlashCommand,
    args: Vec<String>,
    worktree: Option<&zed::Worktree>,
) -> zed::Result<zed::SlashCommandOutput, String> {
    match command.name.as_str() {
        "my-command" => {
            let result = do_something(&args)?;
            Ok(zed::SlashCommandOutput {
                text: result,
                sections: vec![],
                attachments: vec![],
            })
        }
        _ => Err(format!("Unknown command: {}", command.name)),
    }
}

fn complete_slash_command_argument(
    &self,
    command: zed::SlashCommand,
    _args: Vec<String>,
) -> zed::Result<Vec<zed::SlashCommandArgumentCompletion>> {
    Ok(vec![
        zed::SlashCommandArgumentCompletion {
            label: "option-1".to_string(),
            new_text: "option-1".to_string(),
            run_command_in_query: false,
        },
    ])
}
```

---

## Debugger Extensions (DAP)

### Registration

```toml
[debug_adapters.my-dap]
schema_path = "debug_adapter_schemas/my-dap.json"

[debug_locators.my-locator]
```

### Implementation

```rust
fn get_dap_binary(
    &mut self,
    adapter_name: String,
    _config: zed::DebugTaskDefinition,
    _user_provided_debug_adapter_path: Option<String>,
    worktree: &zed::Worktree,
) -> zed::Result<zed::DebugAdapterBinary, String> {
    let path = worktree
        .which(&adapter_name)
        .ok_or_else(|| format!("{} not found", adapter_name))?;

    Ok(zed::DebugAdapterBinary {
        command: Some(path),
        args: vec![],
        env: worktree.shell_env(),
        connection: None,
        use_tcp: false,
    })
}
```

---

## Theme Extensions

### Theme JSON Structure

Place in `themes/my-theme.json`. Follow schema: https://zed.dev/schema/themes/v0.2.0.json

```json
{
    "name": "My Theme Family",
    "author": "Your Name",
    "themes": [
        {
            "name": "My Dark Theme",
            "appearance": "dark",
            "style": {
                "background": "#1a1b26",
                "foreground": "#a9b1d6",
                "accent": "#7aa2f7",
                "border": "#292e42",
                "border.variant": "#1f2335",
                "surface.background": "#1a1b26",
                "title_bar.background": "#1a1b26",
                "toolbar.background": "#1a1b26",
                "editor.background": "#1a1b26",
                "editor.foreground": "#a9b1d6",
                "editor.gutter.background": "#1a1b26",
                "editor.active_line.background": "#292e42",
                "editor.line_number": "#3b4261",
                "editor.active_line_number": "#a9b1d6",
                "terminal.background": "#1a1b26",
                "terminal.foreground": "#a9b1d6",
                "terminal.ansi.black": "#24283b",
                "terminal.ansi.red": "#f7768e",
                "terminal.ansi.green": "#9ece6a",
                "terminal.ansi.yellow": "#e0af68",
                "terminal.ansi.blue": "#7aa2f7",
                "terminal.ansi.magenta": "#ad8ee6",
                "terminal.ansi.cyan": "#7dcfff",
                "terminal.ansi.white": "#a9b1d6",
                "syntax": {
                    "keyword": { "color": "#bb9af7" },
                    "keyword.control": { "color": "#bb9af7" },
                    "string": { "color": "#9ece6a" },
                    "function": { "color": "#7aa2f7" },
                    "type": { "color": "#7dcfff" },
                    "comment": { "color": "#565f89", "font_style": "italic" },
                    "variable": { "color": "#a9b1d6" },
                    "number": { "color": "#ff9e64" },
                    "operator": { "color": "#89ddff" },
                    "property": { "color": "#73daca" },
                    "constant": { "color": "#ff9e64" },
                    "tag": { "color": "#f7768e" }
                },
                "players": [
                    { "cursor": "#7aa2f7", "selection": "#283457" }
                ]
            }
        },
        {
            "name": "My Light Theme",
            "appearance": "light",
            "style": {
                "background": "#e1e2e7",
                "foreground": "#3760bf",
                "editor.background": "#e1e2e7",
                "editor.foreground": "#3760bf"
            }
        }
    ]
}
```

> Use the [Theme Builder](https://zed.dev/theme-builder) to visually design themes.

---

## Snippet Extensions

### Snippet JSON Format

Place in `snippets/my-language.json`:

```json
{
    "function": {
        "prefix": "fn",
        "body": [
            "fn ${1:function_name}(${2:args}) -> ${3:ReturnType} {",
            "    ${4:// TODO: implement}",
            "}",
            "$0"
        ],
        "description": "Create a new function"
    },
    "test": {
        "prefix": "test",
        "body": [
            "#[test]",
            "fn ${1:test_name}() {",
            "    ${2:// TODO: write test}",
            "}"
        ],
        "description": "Create a test function"
    },
    "struct": {
        "prefix": "struct",
        "body": [
            "struct ${1:Name} {",
            "    ${2:field}: ${3:Type},",
            "}"
        ],
        "description": "Create a struct"
    }
}
```

**Tabstop syntax**: `$0` (final cursor), `${1:placeholder}`, `${2:default_value}`.

---

## Extension Capabilities (Security)

Extensions run sandboxed. Users grant capabilities in settings:

```json
{
    "granted_extension_capabilities": [
        { "kind": "process:exec", "command": "*", "args": ["**"] },
        { "kind": "download_file", "host": "github.com", "path": ["**"] },
        { "kind": "npm:install", "package": "*" }
    ]
}
```

### Restricting Capabilities

```json
{
    "granted_extension_capabilities": [
        { "kind": "process:exec", "command": "cargo", "args": ["**"] },
        { "kind": "download_file", "host": "github.com", "path": ["owner", "repo", "**"] }
    ]
}
```

### Capability Kinds

| Capability | Controls |
|------------|----------|
| `process:exec` | Execute external commands |
| `download_file` | Download files from URLs |
| `npm:install` | Install npm packages |

To disable all capabilities: `"granted_extension_capabilities": []`

---

## Development Workflow

### Prerequisites

- **Rust** installed via [rustup](https://www.rust-lang.org/tools/install) (not Homebrew or system packages)
- Node.js (for some extensions using npm packages)

### Install Dev Extension

1. Open Zed → Extensions page → **Install Dev Extension**
2. Select your extension directory
3. Dev extension overrides any published version

### Debugging

```bash
# Run Zed in foreground for verbose logs
zed --foreground

# View logs in Zed: open command palette → "zed: open log"
# Log file locations:
#   Linux: ~/.config/zed/zed.log
#   macOS: ~/Library/Application Support/zed/zed.log

# stdout/stderr from extensions is forwarded to Zed process
# Use println!/dbg! in Rust code, visible with --foreground
```

### Test Workflow

```bash
# 1. Make changes to extension code
# 2. In Zed: Extensions → click "Install Dev Extension" again to rebuild
# 3. Check Zed.log for errors
# 4. Test language features, LSP, themes, etc.
```

---

## Publishing to Zed Marketplace

### License Requirements

Extension repositories **must** include a license file at the root. Accepted:
- Apache 2.0, MIT, BSD 2-Clause, BSD 3-Clause
- CC BY 4.0, GPLv3, LGPLv3, Unlicense, zlib

### Naming Rules

- Extension IDs must be unique
- Cannot contain "zed", "Zed", or "extension"
- Theme extensions: suffix with `-theme`
- Snippet extensions: suffix with `-snippets`
- Language extensions: use the language name (e.g., `rust`, `python`)

### Publishing Process

1. **Fork** [zed-industries/extensions](https://github.com/zed-industries/extensions)
   > Fork to a personal account (not org) so Zed staff can push changes to your PR.

2. **Add submodule**:
```bash
git submodule add https://github.com/you/my-zed-extension.git extensions/my-extension
git add extensions/my-extension
```

3. **Add to extensions.toml**:
```toml
[my-extension]
submodule = "extensions/my-extension"
version = "0.1.0"

# If extension is in a subdirectory:
# [my-extension]
# submodule = "extensions-my-extension"
# path = "packages/zed"
# version = "0.1.0"
```

4. **Sort entries**:
```bash
pnpm sort-extensions
```

5. **Open PR** to `zed-industries/extensions`

### Updating an Extension

```bash
# Update submodule to latest commit
git submodule update --remote extensions/my-extension

# Update version in extensions.toml to match extension.toml
# Open PR with the changes
```

### Additional Publishing Rules

- Language/debugger extensions must NOT ship binaries — they should download or detect them
- Theme and icon theme extensions must be published separately from language extensions
- If an existing extension has issues, fix it upstream first before creating a new one

---

## Extension API Reference

### Key Types

| Type | Description |
|------|-------------|
| `Command` | Process command with args and env |
| `Worktree` | Project workspace (read files, find binaries, get env) |
| `Project` | Zed project context |
| `LanguageServerId` | LSP server identifier |
| `ContextServerId` | MCP server identifier |
| `CodeLabel` | Syntax-highlighted text label |
| `SlashCommand` | AI assistant slash command definition |
| `SlashCommandOutput` | Command response with text, sections, attachments |
| `DebugAdapterBinary` | Debug adapter process configuration |
| `DebugTaskDefinition` | Debug launch configuration |
| `KeyValueStore` | Persistent key-value storage |

### Key Global Functions

| Function | Description |
|----------|-------------|
| `download_file(url, path)` | Download file (requires capability) |
| `latest_github_release(repo, opts)` | Get latest GitHub release |
| `github_release_by_tag_name(repo, tag)` | Get specific release by tag |
| `npm_install_package(pkg)` | Install npm package |
| `npm_package_latest_version(pkg)` | Get latest npm version |
| `npm_package_installed_version(pkg)` | Check installed version |
| `node_binary_path()` | Get Node.js binary path |
| `make_file_executable(path)` | Set executable permission |
| `current_platform()` | Get (OS, Architecture) tuple |

### Worktree Methods

| Method | Description |
|--------|-------------|
| `id()` | Worktree identifier |
| `root_path()` | Project root path |
| `read_text_file(path)` | Read file content |
| `which(binary_name)` | Find binary in PATH |
| `shell_env()` | Get shell environment variables |

---

## Common Patterns

### Download + Cache Language Server

```rust
use zed_extension_api as zed;
use std::path::Path;

struct MyExtension {
    cached_path: Option<String>,
}

impl zed::Extension for MyExtension {
    fn new() -> Self {
        Self { cached_path: None }
    }

    fn language_server_command(
        &mut self,
        _id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        if self.cached_path.is_none() {
            let path = self.ensure_server_binary(worktree)?;
            self.cached_path = Some(path);
        }

        let path = self.cached_path.as_ref().unwrap().clone();
        Ok(zed::Command {
            command: path,
            args: vec!["--stdio".to_string()],
            env: worktree.shell_env(),
        })
    }
}

impl MyExtension {
    fn ensure_server_binary(&self, worktree: &zed::Worktree) -> zed::Result<String> {
        let (os, arch) = zed::current_platform();
        let binary_name = format!("my-lsp-{}-{}", os, arch);
        let binary_path = format!("{}/.cache/{}", worktree.root_path(), binary_name);

        if Path::new(&binary_path).exists() {
            return Ok(binary_path);
        }

        let release = zed::latest_github_release(
            "owner/my-lsp",
            zed::GithubReleaseOptions { require_assets: true },
        )?;

        let asset = release.assets.iter()
            .find(|a| a.name.contains(&binary_name))
            .ok_or_else(|| "No matching release asset".to_string())?;

        zed::download_file(&asset.browser_download_url, &binary_path)?;
        zed::make_file_executable(&binary_path)?;

        Ok(binary_path)
    }
}
```

### Check External Tool Availability

```rust
fn language_server_command(
    &mut self,
    _id: &zed::LanguageServerId,
    worktree: &zed::Worktree,
) -> zed::Result<zed::Command> {
    // Prefer local install, fall back to global
    let local_path = format!("{}/node_modules/.bin/typescript-language-server",
        worktree.root_path());

    let command = if Path::new(&local_path).exists() {
        local_path
    } else {
        worktree.which("typescript-language-server")
            .ok_or_else(|| "typescript-language-server not found. Install with: npm i -g typescript-language-server typescript".to_string())?
    };

    Ok(zed::Command {
        command,
        args: vec!["--stdio".to_string()],
        env: worktree.shell_env(),
    })
}
```

## Best Practices

### Extension Structure

```rust
// ✅ GOOD: Clear module organization
src/
├── lib.rs          // Main entry, register languages/themes
├── language.rs     // Language server implementation
├── theme.rs        // Color definitions
└── snippets.rs     // Snippet collections

// ❌ BAD: Everything in one file
```

### Performance

```rust
// Cache expensive operations
fn expensive_computation(&self) -> Result<Value> {
    if let Some(cached) = &self.cached {
        return Ok(cached.clone());
    }
    // ... compute ...
}

// Lazy initialization
fn get_language(&self) -> &Language {
    self.language.get_or_init(|| /* ... */)
}
```

### Testing

```rust
// Test extension loads correctly
#[test]
fn test_extension_loads() {
    let ext = MyExtension::new();
    assert!(ext.activate().is_ok());
}
```

### Do:
- Keep extension size under 1MB
- Use async for I/O operations
- Test on multiple Zed versions

### Don't:
- Block the main thread
- Use heavy dependencies
- Hardcode paths (use API methods)

---

## References

- **Official Docs**: https://zed.dev/docs/extensions
- **API Reference**: https://docs.rs/zed_extension_api/latest/zed_extension_api/
- **Extensions Registry**: https://zed.dev/extensions
- **Extensions Repo**: https://github.com/zed-industries/extensions
- **Theme Builder**: https://zed.dev/theme-builder
- **Architecture Blog**: https://zed.dev/blog/zed-decoded-extensions