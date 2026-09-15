#!/bin/bash
# CDE Plugin Installation Script
# Run this after Ruby 3.3.12 is installed

set -e

RUBY_DIR="/c/Ruby33-x64"
NEXUSCDE_DIR="/c/Users/andyphung/My Drive/nexuscde"

echo "=== CDE Plugin Installation ==="
echo ""

# Verify Ruby
echo "Checking Ruby..."
"$RUBY_DIR/bin/ruby.exe" --version

# Run bundle install
echo ""
echo "Installing gems..."
export PATH="$RUBY_DIR/bin:$PATH"
cd "$NEXUSCDE_DIR"

# Use Windows-style paths for bundle
bundle install

# Run migrations
echo ""
echo "Running migrations..."
bundle exec rake db:migrate

# Run tests
echo ""
echo "Running CDE tests..."
bundle exec rspec modules/cde/spec/integration/

echo ""
echo "=== Installation Complete ==="
echo ""
echo "To start OpenProject:"
echo "  cd $NEXUSCDE_DIR"
echo "  bundle exec rails server"
