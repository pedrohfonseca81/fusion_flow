#!/bin/bash
# docker-entrypoint.sh

set -e

echo "Waiting for database..."
while ! /app/bin/fusion_flow eval "FusionFlow.Release.migrate" > /dev/null 2>&1; do
  echo "Migration failed, retrying in 2s..."
  sleep 2
done

echo "Migrations successful!"

echo "Starting application..."
exec /app/bin/fusion_flow start
