export QUIT = 1

tests := $(wildcard test_*.vim)

.PHONY: $(tests)

all: $(tests)

$(tests):
	@echo "Test: $@"
	@nvim -u $@
	@vim -n -u NONE -e -s -c "source $@" 2>&1
