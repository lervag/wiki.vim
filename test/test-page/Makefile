MYVIM ?= nvim --headless
export QUIT = 1

tests := $(wildcard test-*.vim)

.PHONY: cleanup $(tests)

test:
	@rm -rf wiki-tmp
	@cp -r wiki wiki-tmp
	@$(MAKE) $(tests)
	@rm -rf wiki-tmp

$(tests):
	@$(MYVIM) -u $@
