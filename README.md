# Introduction

This is a [Vim](http://www.vim.org/) plugin for writing and maintaining
a personal wiki. The plugin was initially based on
[vimwiki](https://github.com/vimwiki/vimwiki), but it is written mostly from
scratch and is based on a more "do one thing and do it well" philosophy.

Note: `wiki.vim` is _not_ a filetype plugin. It is designed so that it may be used
      along with filetype plugins, e.g. for dedicated Markdown plugins. One may
      also use [wiki-ft.vim](https://github.com/lervag/wiki-ft.vim) for simple
      syntax highlighting and folding of `.wiki` files, if desired.

This README file contains basic information on how to get started, as well as
a list of available features. For more details, please confer the
[full documentation](https://github.com/lervag/wiki.vim/blob/master/doc/wiki.txt).

## Table of contents

* [Quick Start](#quick-start)
* [Features](#features)
* [TODO](#todo)
* [Acknowledgements](#acknowledgements)

# Quick Start

## Installation

If you use [vim-plug](https://github.com/junegunn/vim-plug), then add the
following line to your `vimrc` file:

```vim
Plug 'lervag/wiki.vim'
```

Or use some other plugin manager:
- [vundle](https://github.com/gmarik/vundle)
- [neobundle](https://github.com/Shougo/neobundle.vim)
- [pathogen](https://github.com/tpope/vim-pathogen)

## Usage

This outlines the basic steps to get started:

1. Create a wiki directory where the wiki files should be stored, for instance
   `~/documents/wiki`.

2. Add the following to your `vimrc` file:

   ```vim
   let g:wiki_root = '~/documents/wiki'
   ```

3. Now you can open the index file (that is, `index.wiki`) with `<leader>ww`
   and start to add your notes as desired.

# Features

- Wiki functionality
  - Global mappings for accessing a specified wiki
  - Local mappings for
    - Navigation (follow links, go back, etc)
    - Renaming pages (will also update links in other pages)
    - Creating a table of contents
    - Toggling links
    - Viewing wiki link graphs
  - Completion of wiki links and link anchors
  - Text objects
    - `il al` Link url
    - `it at` Link text
- Support for journal entries
  - Navigating the journal back and forth with `<c-j>` and `<c-k>`
  - Support for parsing journal entries in order to make weekly and monthly
    summaries. The parsed result needs manual editing for good results.
- Utility functionality
  - Toggling lists (marking as done/undone or add/remove TODO)
  - Running code snippets (Note: This needs work)
  - Text objects
    - `ic ac` Code blocks
    - `il al` List items
- Third-party support
  - [CtrlP](https://github.com/ctrlpvim/ctrlp.vim): `CtrlPWiki` command
  - [unite](https://github.com/Shougo/unite.vim)
  - [denite](https://github.com/Shougo/denite.nvim)

# TODO

This is a list of TODO items that anyone may follow up on. I am very willing to
accept [contributions](CONTRIBUTING.md), both as issues describing problems or
as pull requests for implementing bug fixes or missing features.

- [x] Implement `WikiEnable`
- [x] Implement `g:wiki_filetypes`
- [ ] Allow to choose the default type of link
- [ ] [vimwiki](https://github.com/vimwiki/vimwiki) like TODO list toggles
      (cf. [#1](../../issues/1))
- [ ] Allow journal entries per week/months (cf. [#2](../../issues/1))
- [ ] Improve the "execute code section" feature

# Related projects

- [vimwiki](https://github.com/vimwiki/vimwiki)
- [vim-waikiki](https://github.com/fcpg/vim-waikiki)

# Acknowledgements

Without [vimwiki](https://github.com/vimwiki/vimwiki), thus plugin would never
have existed. So my thanks go to the smart people that developed and maintains
`vimwiki`, both for the inspiration and for the ideas.

