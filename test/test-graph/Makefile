MYVIM ?= nvim --clean --headless
export QUIT = 1

tests := $(wildcard test-*.vim)

.PHONY: all $(tests)

test: $(tests)

$(tests):
	@$(MYVIM) -u $@
