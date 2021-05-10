MYVIM ?= nvim --headless
# MYVIM ?= vim -T dumb --not-a-term --noplugin -n
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test sysinfo $(TESTS)

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@

sysinfo:
	@echo "**** SYSTEM INFORMATION ****"
	@-git log -1
	@-$(MYVIM) --version
	@echo "**** SYSTEM INFORMATION ****"

#
# Ensure that some goals are run first/last
#
ifndef MAKECMDGOALS
$(TESTS): sysinfo
endif
