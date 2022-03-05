MYVIM ?= nvim --clean --headless
export QUIT = 1

tests := $(wildcard test-*.vim)

.PHONY: cleanup $(tests)

test: $(tests)

WIKI=../wiki-basic
$(tests):
	@rm -rf wiki-tmp
	@cp -r $(WIKI) wiki-tmp
	@$(MYVIM) -u $@
	@rm -rf wiki-tmp

test-rename-md.vim: WIKI=../wiki-markdown
