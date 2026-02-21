#!/bin/bash
# docker-entrypoint.sh

set -e

if [ -z "$SECRET_KEY_BASE" ]; then
  echo "SECRET_KEY_BASE is empty. Generating a random one..."
  export SECRET_KEY_BASE=$(openssl rand -base64 48)
fi

echo "Waiting for database..."
while ! /app/bin/fusion_flow eval "FusionFlow.Release.migrate" > /dev/null 2>&1; do
  echo "Migration failed, retrying in 2s..."
  sleep 2
done

echo "Migrations successful!"

echo "Running seeds..."
/app/bin/fusion_flow eval "FusionFlow.Release.seed"

echo "Starting application..."
exec /app/bin/fusion_flow start
