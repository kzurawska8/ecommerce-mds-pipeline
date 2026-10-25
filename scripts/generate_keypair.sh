#!/usr/bin/env bash
# Generates an encrypted RSA key pair for Snowflake key-pair authentication.
#
# Usage: ./scripts/generate_keypair.sh <name>
#   e.g. ./scripts/generate_keypair.sh terraform_svc
#
# Output (gitignored):
#   keys/<name>_rsa_key.p8   - encrypted private key (PKCS#8), stays secret
#   keys/<name>_rsa_key.pub  - public key, registered on the Snowflake user
set -euo pipefail

name="${1:?Usage: $0 <name>}"
keys_dir="$(cd "$(dirname "$0")/.." && pwd)/keys"
private_key="${keys_dir}/${name}_rsa_key.p8"
public_key="${keys_dir}/${name}_rsa_key.pub"

if [[ -e "$private_key" ]]; then
  echo "Refusing to overwrite existing key: $private_key" >&2
  exit 1
fi

mkdir -p "$keys_dir"
chmod 700 "$keys_dir"

# Ask once and pass it to openssl via env var (never visible in `ps` or shell history).
# Snowflake clients read it from SNOWFLAKE_PRIVATE_KEY_PASSPHRASE (Terraform)
# or the client config (dbt/Python).
read -rsp "Passphrase for ${name}: " passphrase; echo
read -rsp "Confirm passphrase: " confirm; echo
if [[ -z "$passphrase" || "$passphrase" != "$confirm" ]]; then
  echo "Passphrases are empty or do not match." >&2
  exit 1
fi
export KEY_PASSPHRASE="$passphrase"

openssl genrsa 2048 2>/dev/null \
  | openssl pkcs8 -topk8 -v2 aes-256-cbc -inform PEM -passout env:KEY_PASSPHRASE -out "$private_key"
openssl rsa -in "$private_key" -passin env:KEY_PASSPHRASE -pubout -out "$public_key" 2>/dev/null
chmod 600 "$private_key"

echo "Private key: $private_key"
echo "Public key:  $public_key"
echo
echo "Public key body (paste into Snowflake RSA_PUBLIC_KEY if needed):"
grep -v -- "-----" "$public_key" | tr -d '\n'
echo
