{
  description = "pi coding agent — terminal AI assistant, packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/fef9403a3e4d31b0a23f0bacebbec52c248fbb51";

  outputs = { self, nixpkgs }:
    let
      systems      = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (pkgs: rec {
        pi-coding-agent = pkgs.buildNpmPackage {
          pname   = "pi-coding-agent";
          version = "0.75.4";

          # Use the published npm tarball — avoids monorepo workspace root issues
          # (npm would try to hoist deps to the monorepo root which is read-only in Nix).
          src = pkgs.fetchurl {
            url  = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-0.75.4.tgz";
            hash = "sha256-12e1dKKCSyy2dee6hT7Wo9hNw36DUCviKxSuubgY1pc=";
          };

          # npm tarballs always extract to a "package/" directory.
          sourceRoot = "package";

          # Node.js >= 22.19.0 required by the package.
          nodejs = pkgs.nodejs_22;

          npmDepsHash = "sha256-mwHYCt5MkSQVVH3e10vdveUK77/DsYg/jkQpvyJ096E=";

          # The tarball ships pre-built dist/ — skip the TypeScript build step.
          npmFlags       = [ "--ignore-scripts" ];
          dontNpmBuild   = true;

          # Two problems in the published package's npm-shrinkwrap.json:
          #   1. Three sibling packages (pi-agent-core, pi-ai, pi-tui) have no
          #      integrity hash — prefetch-npm-deps requires it. Fixed in the
          #      patched npm-shrinkwrap.json in this repo.
          #   2. Several @types/* devDependencies in package.json are absent from
          #      the shrinkwrap entirely — npm ci fails trying to fetch them.
          #      Fix: use a pre-stripped package.json (no devDependencies); the
          #      compiled dist/ is already in the tarball so they are never needed.
          postPatch = ''
            cp ${./npm-shrinkwrap.json} npm-shrinkwrap.json
            cp ${./package.json} package.json
          '';

          meta = with pkgs.lib; {
            description = "Terminal AI coding assistant with Ollama/custom LLM support";
            homepage    = "https://pi.dev";
            mainProgram = "pi";
            platforms   = platforms.linux;
          };
        };

        default = pi-coding-agent;
      });
    };
}
