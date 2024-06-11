
{ config, lib, pkgs, ... }:
{

  system.stateVersion = "23.05";
  

  
  services.tailscale = {
    enable = true;
    authKeyFile = "/tsauthkey";
    extraUpFlags = [ "--ssh" "--hostname" "flakery-tutorial" ];
  };


}
