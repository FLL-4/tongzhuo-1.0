#!/bin/zsh

set -euo pipefail

if (( $# != 1 )); then
  print -u2 "Usage: $0 /path/to/api.yaml"
  exit 64
fi

source_config=${1:A}
if [[ ! -f "$source_config" ]]; then
  print -u2 "Configuration file not found: $source_config"
  exit 66
fi

if ! grep -q '^text:' "$source_config" || ! grep -q '^image:' "$source_config"; then
  print -u2 "Invalid configuration: expected text and image sections."
  exit 65
fi

bundle_id=${ZAICHANG_BUNDLE_ID:-com.zhengenrong.zaichang}
regular_dir="$HOME/Library/Application Support/Zaichang"
sandbox_dir="$HOME/Library/Containers/$bundle_id/Data/Library/Application Support/Zaichang"

for destination_dir in "$regular_dir" "$sandbox_dir"; do
  mkdir -p "$destination_dir"
  destination_file="$destination_dir/api.yaml"
  if [[ "$source_config" != "${destination_file:A}" ]]; then
    install -m 600 "$source_config" "$destination_file"
  else
    chmod 600 "$destination_file"
  fi
done

print "Installed local API configuration for $bundle_id."
print "Restart the app after changing the configuration."
