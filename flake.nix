{
  description = "dart.nvim";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    inputs@{
      nixpkgs,
      ...
    }:
    let
      systems = builtins.attrNames nixpkgs.legacyPackages;
    in
    inputs.flake-utils.lib.eachSystem systems (
      system:
      let
        version = "0.1.0";
        pkgs = import nixpkgs {
          inherit system;
        };
        dart-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "dart.nvim";
          inherit version;
          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter =
              path: type: type == "directory" || (builtins.match ".*lua" (builtins.baseNameOf path) != null);
          };
        };
        nvim-mini-test = import ./tests/nvim.nix { inherit pkgs; };
        shell = pkgs.mkShell {
          name = "dart-nvim-shell";
          buildInputs = with pkgs; [
            lua-language-server
            stylua
            nvim-mini-test
            (pkgs.writeShellScriptBin "run-tests" ''
              cd $(git rev-parse --show-toplevel)
              "${nvim-mini-test}"/bin/nvim-mini-test --headless -c "lua MiniTest.run()"
            '')
          ];
        };
      in
      {
        packages = {
          default = dart-nvim;
        };
        devShells = {
          default = shell;
        };
      }
    );
}
