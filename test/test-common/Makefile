export QUIT = 1

tests := $(wildcard test_*.vim)

.PHONY: all $(tests)

test: $(tests)

$(tests):
	@echo $@
	@nvim --headless -u $@
	@vim -T dumb --not-a-term --noplugin -n -u $@
