# nix-pi

Nix flake packaging [pi coding agent](https://pi.dev) — a terminal AI assistant with Ollama/custom LLM support.

## Usage

```nix
# flake.nix
inputs.nix-pi.url = "github:hinstef/nix-pi";

# home-manager or environment.systemPackages
home.packages = [ inputs.nix-pi.packages.${pkgs.system}.default ];
```

Then configure Ollama as a provider in `~/.pi/agent/models.json`:

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [{ "id": "qwen2.5-coder:7b" }]
    }
  }
}
```

## Packaging notes

The published `npm-shrinkwrap.json` has two issues this flake works around:

1. Three internal sibling packages (`pi-agent-core`, `pi-ai`, `pi-tui`) are missing `integrity` hashes — fixed in `npm-shrinkwrap.json` in this repo.
2. Several `@types/*` devDependencies in `package.json` are absent from the shrinkwrap — fixed by shipping a stripped `package.json` (no `devDependencies`). The compiled `dist/` is already in the published tarball so they are never needed.

## Updating

When a new version is released:

1. Update `version` in `flake.nix`
2. Update the `src` tarball URL and hash (`nix-prefetch-url --type sha256 <url>` → convert with `nix hash convert --hash-algo sha256 --to sri`)
3. Regenerate `npm-shrinkwrap.json` and `package.json` from the new tarball
4. Set `npmDepsHash = lib.fakeHash` and run `nix build` to get the real hash
