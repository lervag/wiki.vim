MYVIM ?= nvim --headless
export QUIT = 1

tests := $(wildcard test-*.vim)

.PHONY: cleanup $(tests)

test: $(tests)
	@rm -rf wiki-tmp

$(tests):
	@$(MYVIM) -u $@

test-rename.vim: | wiki-tmp

wiki-tmp:
	@cp -r wiki wiki-tmp
