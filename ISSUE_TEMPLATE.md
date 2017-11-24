# Description

The description should provide the details necessary to address the issue.
This typically includes the following:

1. A description of the expected behaviour
2. A description of the observed behaviour
3. The steps required to reproduce the issue

If your issue is instead a feature request or anything else, please consider if
minimal examples and vimrc files might still be relevant.

# Minimal working example

Please provide a minimal working example, for instance something like this:

```
/path/to/minimal-working-example-wiki
├── index.wiki
├── journal
│   └── 2017-11-24.wiki
└── test.wiki
```

The file contents should of course also be included if necessary. Please also
provide a minimal vimrc file, e.g.

```vim
set nocompatible
let &rtp  = '~/.vim/bundle/wiki,' . &rtp

" Load other plugins, if necessary
" let &rtp = '~/path/to/other/plugin,' . &rtp

filetype plugin indent on
syntax enable

let g:wiki = { 'root' : '/path/to/minimal-working-example-wiki' }
```

