{ pkgs, ... }:
let
  nvim-mini-test = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (
    pkgs.neovimUtils.makeNeovimConfig {
      plugins = with pkgs.vimPlugins; [ mini-test ];
      customLuaRC = (builtins.readFile ./minit.lua);
    }
  );
in
nvim-mini-test.overrideAttrs (o: {
  buildPhase = o.buildPhase + ''mv $out/bin/nvim $out/bin/nvim-mini-test'';
})
