#!/bin/bash

# Integration test runner for nvim-chess
# This script helps set up and run integration tests with a real Lichess token

set -e

echo "🧪 nvim-chess Integration Test Runner"
echo "===================================="

# Check if token is provided
if [ -z "$LICHESS_TOKEN" ]; then
    echo "❌ LICHESS_TOKEN environment variable not set"
    echo ""
    echo "To run integration tests, you need a Lichess personal access token:"
    echo ""
    echo "1. Go to https://lichess.org/account/oauth/token"
    echo "2. Create a new token with scopes: board:play, challenge:read, challenge:write"
    echo "3. Set the token as an environment variable:"
    echo ""
    echo "   export LICHESS_TOKEN=your_token_here"
    echo "   ./integration-test.sh"
    echo ""
    echo "Or run directly:"
    echo "   LICHESS_TOKEN=your_token ./integration-test.sh"
    echo ""
    exit 1
fi

echo "✅ LICHESS_TOKEN found"
echo "🔍 Token preview: ${LICHESS_TOKEN:0:8}..."

# Validate token format (basic check)
if [[ ! "$LICHESS_TOKEN" =~ ^lip_[a-zA-Z0-9]{28}$ ]]; then
    echo "⚠️  Warning: Token doesn't match expected Lichess format (lip_XXXX...)"
    echo "   Make sure you're using a valid Lichess personal access token"
    echo ""
fi

# Ask for confirmation
echo ""
echo "This will run integration tests against the real Lichess API."
echo "The tests will:"
echo "  - Validate your token"
echo "  - Fetch your profile"
echo "  - Test API endpoints"
echo "  - Handle rate limiting"
echo "  - Test error scenarios"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🚀 Running integration tests..."
echo ""

# Run the integration tests
make test-integration

echo ""
echo "✅ Integration tests completed!"
echo ""
echo "If any tests failed, check:"
echo "  - Token has correct scopes (board:play, challenge:read, challenge:write)"
echo "  - Network connection is stable"
echo "  - Account is not rate limited"
echo ""
echo "For debugging, you can run individual tests:"
echo "  LICHESS_TOKEN=\$LICHESS_TOKEN nvim --headless -c 'PlenaryBustedFile test/integration_spec.lua' -c 'qa'"