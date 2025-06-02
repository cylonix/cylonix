#! /bin/sh

# Overwrite env from .env.local
sed /^\s*#/d ../.env.local | sed /^\s*$/d | sed 's/^/export /' > ./._tmp_env.local
. ./._tmp_env.local
rm -f ._tmp_env.local

. ./config.defaults.sh
envsubst < ../lib/assets/config.template.yaml > ../lib/assets/config.local.yaml