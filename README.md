# Introduction

This is a [Vim](http://www.vim.org/) plugin for writing and maintaining
a personal wiki in Markdown syntax. It is based on
[vimwiki](https://github.com/vimwiki/vimwiki), but written mostly from scratch.

This README file contains basic information on how to get started, as well as
a list of available features. For complete documentation, please confer the
[full documentation](https://github.com/lervag/wiki/blob/master/doc/wiki.txt).

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
Plug 'lervag/wiki'
```

Or use some other plugin manager:
- [vundle](https://github.com/gmarik/vundle)
- [neobundle](https://github.com/Shougo/neobundle.vim)
- [pathogen](https://github.com/tpope/vim-pathogen)

## Usage

This outlines the basic steps necessary to get started:

1. Create a wiki directory where the wiki files should be stored, for instance
   `~/documents/wiki`.

2. Add the following to your `vimrc` file:

   ```vim
   let g:wiki = { 'root' : '~/documents/wiki' }
   ```

3. Now you can open the index file (that is, `index.wiki`) with `<leader>ww`
   and start to add your notes as desired.

For more details, see the [full
documentation](https://github.com/lervag/wiki/blob/master/doc/wiki.txt).

# Features

- Syntax highlighting for `.wiki` files (only within the personal wiki)
- Completion of wiki links and link anchors
- Mappings
  - Global mappings for accessing the wiki
  - Local mappings for
    - Navigation (follow links, go back, etc)
    - Renaming pages (will also update links in other pages)
    - Creating a table of contents
    - Toggling links
    - Toggling lists (marking as done/undone or add/remove TODO)
    - Running code snippets (Note: This needs work)
    - Viewing wiki link graphs
- Support for journal entries
  - Navigating the journal back and forth with `<c-j>` and `<c-k>`
  - Support for parsing journal entries in order to make weekly and monthly
  summaries. The parsed result needs manual editing for good results.
- Text objects
  - `il al` Link url
  - `it at` Link text
  - `ic ac` Code blocks
- Folds
- Third-party support
  - unite and denite sources

# TODO

This plugin was initially a personal project that I never really intended to
share. After having used it for quite some time, I have realized that it might
be useful to more people. However, there is a lot of work to be done to make
this plugin more community friendly.

This is a list of TODO items that anyone may follow up on. I am very willing to
accept [contributions](CONTRIBUTING.md), both as issues describing problems or
as pull requests for implementing bug fixes or missing features.

- [ ] Write list of "low hanging fruits" for contributions
- [ ] Documentation
  - [ ] Vim docs
    - [x] Document the Markdown syntax, including links and similar
    - [ ] Document each of the currently implemented features
  - [x] README
    - [x] Write a list of implemented features
- [ ] Features
  - [ ] General improvements
    - [ ] Add commands for the various features
    - [ ] Convert current mappings to `<plug>` type mappings and add options to
          allow full customization of mappings
  - [ ] New features
    - [ ] Allow custom url types and remove the personal variants that are not
          useful to others
    - [ ] Add automatic detection of a wiki (e.g. based on root level
          `index.wiki` file)  
          This will make the `g:wiki.root` setting unnecessary. Wiki links
          should always be internal to the current wiki, but one could make
          links to external wikis by linking to the absolute path of the
          external wiki.
    - [ ] [vimwiki](https://github.com/vimwiki/vimwiki) like TODO list toggles
          (cf. [#1](../../issues/1))
    - [ ] Allow journal entries per week/months (cf. [#2](../../issues/1))
- [x] Add ISSUE_TEMPLATE.md
- [x] Add CONTRIBUTING.md

# Acknowledgements

Without [vimwiki](https://github.com/vimwiki/vimwiki), thus plugin would never
have existed. So my thanks go to the smart people that developed and maintains
`vimwiki`, both for the inspiration and for the ideas.

