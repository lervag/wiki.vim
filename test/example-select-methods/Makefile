.PHONY: default

default: fzf fzf.vim

fzf:
	@git clone --depth 1 https://github.com/junegunn/fzf
	@FZF_VERSION=vimtex-test make -C fzf bin/fzf

fzf.vim:
	@git clone --depth 1 https://github.com/junegunn/fzf.vim
