#!/bin/bash
# CDE Plugin - Install and Verify Script
# Run this in MSYS2 or Git Bash

set -e

echo "=== CDE Plugin Installation ==="
echo ""

# Check Ruby
echo "Ruby version:"
ruby --version

# Navigate to nexuscde
cd "/c/Users/andyphung/My Drive/nexuscde"

# Install gems
echo ""
echo "Installing gems..."
bundle install

# Run migrations
echo ""
echo "Running migrations..."
bundle exec rake db:migrate

# Run tests
echo ""
echo "Running CDE integration tests..."
bundle exec rspec modules/cde/spec/integration/

echo ""
echo "=== Installation Complete ==="
echo ""
echo "To start OpenProject:"
echo "  cd /c/Users/andyphung/My\ Drive/nexuscde"
echo "  bundle exec rails server"
