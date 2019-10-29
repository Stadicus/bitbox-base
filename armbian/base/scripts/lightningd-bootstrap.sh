#! /bin/sh
# Simple script to bootstrap a running mainnet node.

# Original script
# https://raw.githubusercontent.com/ElementsProject/lightning/master/contrib/bootstrap-node.sh
# --------------------------------------------------------------------------------------------
# Adapted script, by Shift Cryptosecurity AG, Switzerland
# https://github.com/digitalbitbox/bitbox-base
# ------------------------------------------------------------------------------

set -e

# configured for for mainnet
LCLI='lightning-cli --lightning-dir=/mnt/ssd/bitcoin/.lightning'

if ! $LCLI "$@" -H getinfo | grep 'network=bitcoin'; then
    echo "lightningd not running, or not on mainnet?" >&2
    exit 1
fi

# Pick two random peers from this list, and connect to them.
# IPV4: 024b9a1fa8e006f1e3937f65f66c408e6da8e1ca728ea43222a7381df1cc449605@128.199.202.168
# IPV4: 0204a2b95b4c208383d7f02e741a8bfd5b5b7e8bea8d1543b1255da8342d9f2c6b@172.81.178.189
# IPV4: 020ca546d600037181b7cbcd094818100d780d32fd9f210e14390e0d10b7ec71fb@187.65.218.133
# IPV4: 0216006237022044d9bdb73ca51af267c5f67cf76095b4c6275f1162eb422fed68@108.7.50.215
# IPV4: 0219fc8bad855d3c861166a89d637950242230fd3d475bb4a2d1da8c89b97beb0a@78.94.255.174
# IPV4: 024b00cf3368dbff39daa6de5638cd877b96227066e1e0d31b10183daa63ac325d@94.156.174.22
# IPV4: 0260fab633066ed7b1d9b9b8a0fac87e1579d1709e874d28a0d171a1f5c43bb877@54.245.57.153
# IPV4: 027cb5b394c5330467081901dba14d48a4ac0f10012e5791e725a65d326405a82e@82.40.164.125
# IPV4: 02827a7ba367d10a29f0a178be878f737292889d1926b40301780d7e1402a90a72@18.223.138.245
# IPV4: 02866bd9513e4e82f250c9b8a0b83cabc9be3c4824f7016bd160859d0fad3d8920@153.126.136.98
# IPV4: 029d50d59c78b81a39f4ca40b6bc9b89710542a31429b69aa075b91b587979205d@185.228.137.238
# IPV4: 02a5d937fd2328e1a48fd56769ab6ea810fa9c67bfac233f0ac864494b5442d483@82.94.35.199
# IPV4: 02ae3c06f6db6a87ea874ef7ba86c87ab0041eabf6d8be0594582505b1fd5d7ee8@76.103.92.123
# IPV4: 02f40890af885da4673f0ee9725ee74bb2c66d6491cc4334056a2701057993e61d@88.198.91.250
# IPV4: 02fd98ebd4cbedd1317d629d62d192cf943f0134c61464de48f1e232d861de4ef9@52.55.248.131
# IPV4: 0307a3fb98c026148e69f51f1851b41db6dc2abf58e77e588636a60ce85c82f091@46.4.79.166
# IPV4: 03144fcc73cea41a002b2865f98190ab90e4ff58a2ce24d3870f5079081e42922d@5.9.83.143
# IPV4: 034cfb8dcb453372e8f13915cc770bcd7bb0f0809dd1b47c0c3b43b969ff9ff3b7@206.189.62.95
# IPV4: 039437e5ba3cd7168394d08fd1e423a613084e3d30d31d8069a6ded0921bc5b6b6@37.8.237.243
# IPV4: 03beddc8adbf7d56a7da15cdaf95d97b24d07088c3571b421c0e6f9d551a210342@148.251.40.218
# IPV4: 03e24db0341fff731e24aeb0492e54510d1392d21d121a51e644ac5797300d495f@46.101.112.24
# IPV4: 03ee180e8ee07f1f9c9987d98b5d5decf6bad7d058bdd8be3ad97c8e0dd2cdc7ba@85.214.212.104
# IPV4: 03f2d334ab70d50623c889400941dc80874f38498e7d09029af0f701d7089aa516@158.174.131.171

NUM=$(grep -c '^# IPV4:' "$0")
PEERS=$(grep '^# IPV4:' "$0" | head -n $(($(date +%s) % (NUM - 3) )) | tail -n 3 | cut -d' ' -f3-)

for p in $PEERS; do
    echo "Trying to connect to random peer $p..."
    $LCLI "$@" connect "$p" || true
done
