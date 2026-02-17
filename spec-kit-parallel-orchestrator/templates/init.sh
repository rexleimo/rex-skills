#!/bin/bash
# init.sh - Environment check script
# Customize this script to verify your project's dependencies
# This script runs at the start of each harness session

set -euo pipefail

echo "=== Environment Check ==="
echo "Project: $(basename "$PWD")"
echo "Time: $(date)"
echo ""

# ========================================
# Node.js Projects (uncomment if needed)
# ========================================

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js: $NODE_VERSION"
else
    echo "✗ Node.js not found"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✓ npm: $NPM_VERSION"
else
    echo "✗ npm not found"
    exit 1
fi

# Check if node_modules exists
if [ -d "node_modules" ]; then
    echo "✓ node_modules exists"
else
    echo "⚠ node_modules not found. Run 'npm install' first."
    exit 1
fi

# ========================================
# Python Projects (uncomment if needed)
# ========================================

# if command -v python3 &> /dev/null; then
#     PYTHON_VERSION=$(python3 --version)
#     echo "✓ Python: $PYTHON_VERSION"
# else
#     echo "✗ Python not found"
#     exit 1
# fi

# if [ -d "venv" ]; then
#     echo "✓ Virtual environment exists"
# else
#     echo "⚠ Virtual environment not found"
# fi

# ========================================
# Docker Projects (uncomment if needed)
# ========================================

# if command -v docker &> /dev/null; then
#     DOCKER_VERSION=$(docker --version)
#     echo "✓ Docker: $DOCKER_VERSION"
# else
#     echo "✗ Docker not found"
#     exit 1
# fi

# ========================================
# Environment Variables
# ========================================

# Check required environment variables
# REQUIRED_VARS=("DATABASE_URL" "API_KEY" "SECRET_KEY")
# for var in "${REQUIRED_VARS[@]}"; do
#     if [ -z "${!var:-}" ]; then
#         echo "✗ Missing environment variable: $var"
#         exit 1
#     else
#         echo "✓ $var is set"
#     fi
# done

# ========================================
# Database Connection (uncomment if needed)
# ========================================

# if command -v psql &> /dev/null; then
#     if psql -h localhost -U postgres -c "SELECT 1" > /dev/null 2>&1; then
#         echo "✓ Database connection OK"
#     else
#         echo "✗ Cannot connect to database"
#         exit 1
#     fi
# fi

# ========================================
# Custom Checks
# ========================================

# Add your project-specific checks here:
# - Configuration files exist
# - Services are running
# - Required tools are installed

echo ""
echo "=== Environment OK ==="
