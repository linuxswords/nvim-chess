# Makefile for nvim-chess development

.PHONY: test test-unit test-integration demo lint install-deps help

# Default target
help:
	@echo "nvim-chess development commands:"
	@echo ""
	@echo "Testing:"
	@echo "  test           - Run unit tests"
	@echo "  test-all       - Run all tests (currently same as test)"
	@echo "  test-unit      - Run unit tests"
	@echo "  test-integration - Show integration test info (not yet implemented)"
	@echo "  demo           - Run interactive demo"
	@echo ""
	@echo "Development:"
	@echo "  lint           - Run linting (if selene/luacheck available)"
	@echo "  install-deps   - Install development dependencies"
	@echo ""
	@echo "Quick testing:"
	@echo "  make demo      - Quick way to test functionality"

# Run all tests
test: test-unit

# Run all tests (currently same as test, since integration tests not implemented)
test-all: test-unit

# Run unit tests with plenary
test-unit:
	@echo "Running unit tests..."
	@nvim --headless -c "PlenaryBustedDirectory test/ --exclude=integration" -c "qa"

# Run integration tests (requires LICHESS_TOKEN)
# Get token from: https://lichess.org/account/oauth/token
test-integration:
	@if [ -z "$$LICHESS_TOKEN" ]; then \
		echo "⚠️  LICHESS_TOKEN environment variable not set"; \
		echo "   Integration tests will be skipped (marked as pending)"; \
		echo "   To run with real API: export LICHESS_TOKEN=your_token"; \
		echo "   Get token from: https://lichess.org/account/oauth/token"; \
		echo ""; \
	fi
	@echo "Running integration tests..."
	@nvim --headless -c "PlenaryBustedDirectory test/integration/" -c "qa"


# Interactive demo
demo:
	@echo "Starting interactive demo..."
	@nvim -c "set runtimepath+=." -c "ChessDemo interactive"

# Quick functionality test
quick-test:
	@echo "Running quick functionality test..."
	@nvim --headless \
		-c "set runtimepath+=." \
		-c "lua require('nvim-chess.test-utils.demo').quick_test()" \
		-c "sleep 5" \
		-c "qa"

# Benchmark test
bench:
	@echo "Running benchmark..."
	@nvim --headless \
		-c "set runtimepath+=." \
		-c "lua require('nvim-chess.test-utils.demo').benchmark_board_rendering()" \
		-c "sleep 2" \
		-c "qa"

# Linting (if tools are available)
lint:
	@if command -v selene >/dev/null 2>&1; then \
		echo "Running selene..."; \
		selene lua/; \
	elif command -v luacheck >/dev/null 2>&1; then \
		echo "Running luacheck..."; \
		luacheck lua/; \
	else \
		echo "No linting tools found (selene or luacheck)"; \
	fi


# Install development dependencies (basic)
install-deps:
	@echo "Development dependencies:"
	@echo "1. Install plenary.nvim in your Neovim config"
	@echo "2. Optional: Install selene for linting (cargo install selene)"
	@echo "3. Optional: Install luacheck for linting (luarocks install luacheck)"

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@rm -f luacov.*.out

# Development server (interactive testing)
dev:
	@echo "Starting development mode..."
	@nvim -c "set runtimepath+=." -c "ChessMock on" -c "ChessDemo interactive"