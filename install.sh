#!/bin/bash
# Install funnelwise into your Flutter project.
# Usage: curl -s https://raw.githubusercontent.com/gp-juit/funnelwise/main/install.sh | bash

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}Installing funnelwise...${NC}\n"

# Must be in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
  echo "Error: No pubspec.yaml found. Run this from your Flutter project root."
  exit 1
fi

# 1. Clone skill files into .claude/
echo -e "${CYAN}Setting up Claude Code skill...${NC}"
TEMP=$(mktemp -d)
git clone --quiet --depth 1 https://github.com/gp-juit/funnelwise.git "$TEMP"

mkdir -p .claude/commands .claude/hooks/scripts

cp "$TEMP/commands/test-funnel.md" .claude/commands/
cp "$TEMP/commands/list-events.md" .claude/commands/
cp "$TEMP/hooks/hooks.json" .claude/hooks/
cp "$TEMP/hooks/scripts/setup.sh" .claude/hooks/scripts/
chmod +x .claude/hooks/scripts/setup.sh

rm -rf "$TEMP"

# 2. Add package to pubspec.yaml
if ! grep -q "funnelwise" pubspec.yaml 2>/dev/null; then
  echo -e "${CYAN}Adding funnelwise to pubspec.yaml...${NC}"
  if grep -q "flutter_lints" pubspec.yaml; then
    sed -i.bak '/flutter_lints:.*/a\
  integration_test:\
    sdk: flutter\
  funnelwise:\
    git:\
      url: https://github.com/gp-juit/funnelwise.git' pubspec.yaml
  else
    sed -i.bak '/dev_dependencies:/a\
  integration_test:\
    sdk: flutter\
  funnelwise:\
    git:\
      url: https://github.com/gp-juit/funnelwise.git' pubspec.yaml
  fi
  rm -f pubspec.yaml.bak
  flutter pub get
fi

# 3. Create directories
mkdir -p integration_test test/funnels test_reports

# 4. Add test_reports to .gitignore
if [ -f ".gitignore" ]; then
  grep -q "test_reports" .gitignore 2>/dev/null || echo "/test_reports/" >> .gitignore
fi

echo ""
echo -e "${BOLD}${GREEN}funnelwise installed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Add 3 lines to your analytics service (one-time):"
echo ""
echo "     import 'package:funnelwise/funnelwise.dart';"
echo ""
echo "     // Inside your trackEvent method, add before the real SDK call:"
echo "     if (TestableAnalytics.isEnabled) TestableAnalytics.capture(event, props);"
echo ""
echo "  2. Start using:"
echo "     /list-events                                    # See your events"
echo "     /test-funnel signup: signup_view -> signup_success  # Test a funnel"
echo ""
