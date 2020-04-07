MYVIM ?= nvim --headless
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

sysinfo:
	@echo "**** SYSTEM INFORMATION ****"
	@-git log -1
	@-$(MYVIM) --version
	@echo "**** SYSTEM INFORMATION ****"

$(TESTS):
	$(MAKE) -C $@

#
# Ensure that some goals are run first/last
#
ifndef MAKECMDGOALS
test: sysinfo
$(TESTS): sysinfo
endif
