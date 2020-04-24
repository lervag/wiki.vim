MYVIM ?= nvim --headless
export QUIT = 1

tests := $(wildcard test-*.vim)

.PHONY: cleanup $(tests)

test: $(tests)

$(tests):
	@rm -rf wiki-tmp
	@cp -r wiki wiki-tmp
	@$(MYVIM) -u $@
	@rm -rf wiki-tmp
