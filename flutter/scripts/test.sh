#!/bin/bash
# Test script for CompostKaki Flutter app

set -e

echo "🧪 Running CompostKaki Flutter Tests"
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to flutter directory
cd "$(dirname "$0")/.."

# Step 1: Format check
echo ""
echo "📝 Step 1: Checking code formatting..."
if flutter format --set-exit-if-changed lib/ test/; then
    echo -e "${GREEN}✓ Code formatting passed${NC}"
else
    echo -e "${RED}✗ Code formatting failed${NC}"
    echo "Run 'flutter format lib/ test/' to fix"
    exit 1
fi

# Step 2: Static analysis
echo ""
echo "🔍 Step 2: Running static analysis..."
if flutter analyze; then
    echo -e "${GREEN}✓ Static analysis passed${NC}"
else
    echo -e "${RED}✗ Static analysis failed${NC}"
    exit 1
fi

# Step 3: Run unit tests
echo ""
echo "🧪 Step 3: Running unit tests..."
if flutter test --coverage; then
    echo -e "${GREEN}✓ Unit tests passed${NC}"
else
    echo -e "${RED}✗ Unit tests failed${NC}"
    exit 1
fi

# Step 4: Coverage report
echo ""
echo "📊 Step 4: Generating coverage report..."
if command -v lcov &> /dev/null && command -v genhtml &> /dev/null; then
    lcov --summary coverage/lcov.info
    genhtml coverage/lcov.info -o coverage/html
    echo -e "${GREEN}✓ Coverage report generated at coverage/html/index.html${NC}"
else
    echo -e "${YELLOW}⚠ lcov/genhtml not found, skipping HTML coverage report${NC}"
    echo "Coverage data available in coverage/lcov.info"
fi

# Success
echo ""
echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""
echo "Next steps:"
echo "  • View coverage: open coverage/html/index.html"
echo "  • Run integration tests: flutter test integration_test/"
echo "  • Build APK: flutter build apk --release"

