#!/bin/sh

if [[ $# -ne 1 ]]; then
  echo "Needs the tmp file"
  echo "eg: nix_sources $TMP"
  exit
fi

tmp=${1:-"./tmp"}
holder=$tmp/holder
versions=("22.11" "unstable")

mkdir -p ${tmp}
mkdir -p "${tmp}/results"

alias nix="nix --experimental-features 'nix-command flakes'"

for v in ${versions[*]}; {
  rm -rf "$tmp/NixOS-*"
  rm -rf "$tmp/nix-community*"

  #
  # NixOS Options
  #

  rm -rf "$holder"
  curl -L  https://github.com/NixOS/nixpkgs/tarball/nixos-$v | tar -xz -C $tmp
  mv $tmp/NixOS-nixpkgs-* "$holder"
  nix-build $holder/nixos/release.nix -A options -o $tmp/results/nixos_$v

  #
  # Home Manager Options
  #

  rm -rf "$holder"
  hm_version=$([[ $v == "unstable" ]] && echo "master" || echo "release-$v")
  curl -L  https://github.com/nix-community/home-manager/tarball/$hm_version | tar -xz -C $tmp
  mv $tmp/nix-community-home-manager-* "$holder"
  nix build path:$holder\#docs-json -o $tmp/results/home_manager_$v
}
