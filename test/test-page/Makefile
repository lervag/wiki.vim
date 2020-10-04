MYVIM ?= nvim --headless
export QUIT = 1

tests := $(wildcard test-*.vim)

.PHONY: cleanup $(tests)

test: $(tests)

WIKI=wiki-1
$(tests):
	@rm -rf wiki-tmp
	@cp -r $(WIKI) wiki-tmp
	@$(MYVIM) -u $@
	@rm -rf wiki-tmp

test-rename-md.vim: WIKI=wiki-2
