# Makefile for nvim-chess development

.PHONY: test test-unit test-integration demo lint format install-deps help

# Default target
help:
	@echo "nvim-chess development commands:"
	@echo ""
	@echo "Testing:"
	@echo "  test           - Run all tests"
	@echo "  test-unit      - Run unit tests only"
	@echo "  test-demo      - Run demo/integration tests"
	@echo "  demo           - Run interactive demo"
	@echo ""
	@echo "Development:"
	@echo "  lint           - Run linting (if selene/luacheck available)"
	@echo "  format         - Format code with stylua (if available)"
	@echo "  install-deps   - Install development dependencies"
	@echo ""
	@echo "Quick testing:"
	@echo "  make demo      - Quick way to test functionality"

# Run all tests
test: test-unit test-demo

# Run unit tests with plenary
test-unit:
	@echo "Running unit tests..."
	@nvim --headless -c "PlenaryBustedDirectory test/" -c "qa"

# Run demo tests
test-demo:
	@echo "Running demo tests..."
	@nvim --headless \
		-c "set runtimepath+=." \
		-c "lua require('nvim-chess.test-utils.demo').run_basic_demo()" \
		-c "sleep 3" \
		-c "lua require('nvim-chess.test-utils.demo').test_error_scenarios()" \
		-c "sleep 3" \
		-c "qa"

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

# Formatting (if stylua is available)
format:
	@if command -v stylua >/dev/null 2>&1; then \
		echo "Formatting with stylua..."; \
		stylua lua/; \
	else \
		echo "stylua not found - skipping formatting"; \
	fi

# Install development dependencies (basic)
install-deps:
	@echo "Development dependencies:"
	@echo "1. Install plenary.nvim in your Neovim config"
	@echo "2. Optional: Install selene for linting (cargo install selene)"
	@echo "3. Optional: Install stylua for formatting (cargo install stylua)"
	@echo "4. Optional: Install luacheck for linting (luarocks install luacheck)"

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	@find . -name "*.tmp" -delete 2>/dev/null || true

# Development server (interactive testing)
dev:
	@echo "Starting development mode..."
	@nvim -c "set runtimepath+=." -c "ChessMock on" -c "ChessDemo interactive"