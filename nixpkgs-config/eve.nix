{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./common.nix
  ];
  home.packages = let
    weechat-unwrapped = pkgs.weechat-unwrapped.override {
      inherit python3Packages;
    };
    weechatScripts = pkgs.weechatScripts.override {
      inherit python3Packages;
    };
    weechat = pkgs.wrapWeechat weechat-unwrapped {};
  in [
    pkgs.profanity
    (weechat.override {
      configure = {availablePlugins, ...}: {
        scripts = with weechatScripts; [
          wee-slack
          multiline
          weechat-matrix
        ];
        plugins = [
          availablePlugins.python
          availablePlugins.perl
          availablePlugins.lua
        ];
      };
    })

    # for development
    pkgs.kubectl
    pkgs.kotlin-language-server
    pkgs.yq-go
  ];
}
