"""wiki source for denite"""

from re import split
from .base import Base


class Source(Base):
    """Define the wiki source class"""

    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'wiki'
        self.kind = 'file'
        self.matchers = ['matcher_substring']

    def gather_candidates(self, context):
        """Gather wiki file candidates"""
        ext = self.vim.eval(
            "exists('b:wiki') ? b:wiki.extension : g:wiki_filetypes[0]")
        files = self.vim.eval(
            'globpath(wiki#get_root(), "**/*.' + ext + '", 0, 1)')

        return [{
            'word': split('\.?wiki\/?', x)[1],
            'action__path': x,
        } for x in files]
