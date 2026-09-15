@echo off
REM CDE Plugin - Bundle Install Script
REM Run this from MSYS2 shell or Git Bash

echo "=== CDE Plugin Installation ==="
echo ""

REM Check Ruby
echo "Ruby version:"
ruby --version

REM Navigate to nexuscde
cd "/c/Users/andyphung/My Drive/nexuscde"

REM Install gems
echo ""
echo "Installing gems..."
bundle install

REM Run migrations
echo ""
echo "Running migrations..."
bundle exec rake db:migrate

REM Run tests
echo ""
echo "Running CDE integration tests..."
bundle exec rspec modules/cde/spec/integration/

echo ""
echo "=== Installation Complete ==="
