# Introduction

This is a [Vim](http://www.vim.org/) and [neovim](https://neovim.io/) plugin for writing and maintaining
a personal wiki. The plugin was initially based on
[vimwiki](https://github.com/vimwiki/vimwiki), but it is written mostly from
scratch and is based on a more "do one thing and do it well" philosophy.

This README file contains basic information on how to get started, as well as
a list of available features. For more details, please read the
[full documentation](doc/wiki.txt).

Note: `wiki.vim` is _not_ a filetype plugin. It is designed to be used _with_
      filetype plugins, e.g. dedicated Markdown plugins. Users are adviced to
      read `:help wiki-intro-plugins` for a list of plugins that work well with
      `wiki.vim`.

Note: `wiki.vim` requires Vim 9.1 or Neovim 0.9.5.

## Table of contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Acknowledgements](#acknowledgements)
- [Alternatives](#alternatives)

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
   `~/wiki`.

2. Add the following to your `vimrc` file:

   ```vim
   let g:wiki_root = '~/wiki'
   ```

3. Now you can open the index file (by default `index.wiki`) with `<leader>ww`
   and start to add your notes as desired.

Please also read the `Guide` section in the [documentation](doc/wiki.txt).

# Features

- Wiki functionality
  - Global
    - Commands (and mappings) to access a pre-specified wiki (`g:wiki_root`)
      - `WikiIndex` to open the index
      - `WikiJournal` to open the journal
      - `WikiPages` to select from list of all pages
      - `WikiTags` to select from list of tags
  - Local commands and mappings for
    - Navigation (follow links, go back, etc)
    - Renaming pages (will also update links in other pages)
    - Navigate through a table of contents (`WikiToc`)
    - Creating a table of contents (`WikiTocGenerate`)
    - Transforming links (from text to link or between link types)
    - Viewing wiki link graphs
    - Displaying incoming links (see `WikiLinkIncomingToggle`)
  - Completion of wiki links and link anchors
  - Text objects
    - `iu au` Link URL
    - `it at` Link text
  - New page templates
- Support for journal entries
  - Navigating the journal back and forth with `<c-j>` and `<c-k>`
  - Support for parsing journal entries in order to make weekly and monthly
    summaries. The parsed result needs manual editing for good results.
- Utility functionality
  - `:WikiExport` command for exporting to e.g. `pdf` with `pandoc`
- Third-party support
  - [ncm2](https://github.com/ncm2/ncm2): SubscopeDetector for nested completion

# Acknowledgements

Without [vimwiki](https://github.com/vimwiki/vimwiki), this plugin would never
have existed. So my thanks go to the smart people that developed and maintains
`vimwiki`, both for the inspiration and for the ideas.

# Alternatives

Feel free to consider any of the many available alternatives. There are likely many more, but these are the ones I'm aware of:

* [Vimwiki](https://github.com/vimwiki/vimwiki)
* [neorg](https://github.com/nvim-neorg/neorg)
* [tdo.nvim](https://github.com/2KAbhishek/tdo.nvim)
* [notes.nvim](https://github.com/dhananjaylatkar/notes.nvim)

