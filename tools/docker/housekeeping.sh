#!/bin/bash

set -e

echo "🚨 This will remove all unused Docker images, containers, volumes, and networks."
read -p "Are you sure you want to continue? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
  echo "🧹 Pruning all unused Docker resources..."
  docker system prune -a --volumes -f
  echo "✅ Finished Docker system prune."
else
  echo "❌ Prune cancelled."
fi
