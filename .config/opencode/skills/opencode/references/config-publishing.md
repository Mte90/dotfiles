<!-- Loaded on demand from ../SKILL.md -->

# Configuration, Build & Publishing

## Configuration

### Install a plugin

In `~/.config/opencode/opencode.json`:

```jsonc
{
  "plugin": [
    "my-plugin@1.0.0",                    // from npm
    "file:///abs/path/to/dist/index.js",  // local development
    ["file:///abs/path/to/dist/index.js", { "enabled": true, "debug": true }]  // with options
  ],
  "autoupdate": true
}
```

Options are passed as the second argument to the Plugin function. With `autoupdate: true`, the highest semver version in the npm registry wins.

### Plugin options pattern

```typescript
export const MyPlugin: Plugin = async (ctx, options = {}) => {
  const enabled = options.enabled !== false   // default true
  const timeout = options.timeoutMs ?? 30_000

  if (!enabled) {
    return { event: async () => {}, config: async () => {} }
  }
  // ...
}
```

### Two install locations — know the difference

OpenCode resolves plugins from **two** places. Updates must touch both or you get stale loads:

| Location | Purpose |
|----------|---------|
| `~/.cache/opencode/packages/<name>@<ver>/` | Download cache. Contains `node_modules/`, `dist/`, `package-lock.json`. |
| `~/.config/opencode/node_modules/<name>/` | Runtime resolution via `bun.lock` + `package.json` in `~/.config/opencode/`. |

The `~/.config/opencode/package.json` caret-pins versions (e.g. `"opencode-auto-resume": "^1.0.15"`), and `bun.lock` locks resolution. To force a specific version: edit `package.json`, delete `bun.lock`, run `bun install` in `~/.config/opencode/`.

To clear all cached versions and force a fresh download:

```bash
rm -rf ~/.cache/opencode/packages/opencode-auto-resume@*
rm -rf ~/.local/share/reflex/bun/install/cache/opencode-auto-resume@*
cd ~/.config/opencode && bun install
```

---

## Build Configuration

```json
{
  "name": "my-opencode-plugin",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "bun build src/index.ts --outdir dist --target bun",
    "dev": "bun build src/index.ts --outdir dist --target bun --watch",
    "test": "bun test",
    "prepublishOnly": "bun run build"
  },
  "files": ["dist/index.js", "README.md", "LICENSE"],
  "dependencies": {
    "@opencode-ai/plugin": "latest"
  },
  "devDependencies": {
    "@opencode-ai/sdk": "latest",
    "@types/bun": "latest",
    "typescript": "latest"
  }
}
```

> `--target bun` is required — OpenCode runs on bun. The output is a single bundled `dist/index.js` (a virtual filesystem `/$bunfs/root/...`).

---

## Publishing & Distribution

### Package Structure

```
my-opencode-plugin/
├── package.json
├── tsconfig.json
├── src/
│   └── index.ts
├── dist/
│   └── index.js
└── README.md
```

### package.json

```json
{
  "name": "opencode-plugin-mytool",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "peerDependencies": {
    "@opencode-ai/plugin": "^1.0.0"
  },
  "keywords": [
    "opencode",
    "plugin",
    "ai",
    "coding-assistant"
  ]
}
```

### Publishing to npm

```bash
# Build
npm run build

# Test
npm test

# Publish
npm publish --access public
```

### Local Development

```bash
# Link for local testing
npm link

# In opencode config
{
  "plugins": ["opencode-plugin-mytool"]
}
```