#!/bin/bash
# Auto-setup funnelwise when plugin is installed.
# Runs on SessionStart — checks if Flutter project, adds package if missing.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
cd "$PROJECT_DIR" || exit 0

# Only run in Flutter projects
if [ ! -f "pubspec.yaml" ]; then
  exit 0
fi

CHANGED=false

# 1. Add funnelwise if not present
if ! grep -q "funnelwise" pubspec.yaml 2>/dev/null; then
  echo '{"status": "installing funnelwise package..."}' >&2

  # Find the dev_dependencies section and add the package
  if grep -q "dev_dependencies:" pubspec.yaml; then
    # Add after flutter_lints or last dev_dependency
    if grep -q "flutter_lints" pubspec.yaml; then
      sed -i.bak '/flutter_lints:.*/a\
  integration_test:\
    sdk: flutter\
  funnelwise:\
    git:\
      url: https://github.com/gp-juit/funnelwise.git' pubspec.yaml
      rm -f pubspec.yaml.bak
    else
      sed -i.bak '/dev_dependencies:/a\
  integration_test:\
    sdk: flutter\
  funnelwise:\
    git:\
      url: https://github.com/gp-juit/funnelwise.git' pubspec.yaml
      rm -f pubspec.yaml.bak
    fi
    CHANGED=true
  fi
fi

# 2. Add integration_test SDK if not present
if ! grep -q "integration_test:" pubspec.yaml 2>/dev/null; then
  if grep -q "dev_dependencies:" pubspec.yaml; then
    sed -i.bak '/dev_dependencies:/a\
  integration_test:\
    sdk: flutter' pubspec.yaml
    rm -f pubspec.yaml.bak
    CHANGED=true
  fi
fi

# 3. Run flutter pub get if changes were made
if [ "$CHANGED" = true ]; then
  flutter pub get 2>/dev/null || true
fi

# 4. Create test_reports in .gitignore if not present
if [ -f ".gitignore" ]; then
  if ! grep -q "test_reports" .gitignore 2>/dev/null; then
    echo "/test_reports/" >> .gitignore
  fi
fi

# 5. Create integration_test directory if missing
mkdir -p integration_test test/funnels test_reports

echo '{"continue": true}'
exit 0
