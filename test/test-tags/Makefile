MYVIM ?= nvim --clean --headless
export QUIT = 1

tests := $(wildcard test*.vim)

.PHONY: all $(tests)

test: $(tests)

$(tests):
	@rm -rf wiki-tmp
	@cp -r $(WIKI) wiki-tmp
	@$(MYVIM) -u $@
	@rm -rf wiki-tmp

test-defaults.vim: WIKI=../wiki-basic
test-custom-yaml.vim: WIKI=../wiki-markdown
