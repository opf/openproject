# redminehelper: Redmine helper extension for Mercurial
#
# Copyright 2010 Alessio Franceschelli (alefranz.net)
# Copyright 2010-2011 Yuya Nishihara <yuya@tcha.org>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""helper commands for Redmine to reduce the number of hg calls

To test this extension, please try::

    $ hg --config extensions.redminehelper=redminehelper.py rhsummary

I/O encoding:

:file path: urlencoded, raw string
:tag name: utf-8
:branch name: utf-8
:node: 12-digits (short) hex string

Output example of rhsummary::

    <?xml version="1.0"?>
    <rhsummary>
      <repository root="/foo/bar">
        <tip revision="1234" node="abcdef0123..."/>
        <tag revision="123" node="34567abc..." name="1.1.1"/>
        <branch .../>
        ...
      </repository>
    </rhsummary>

Output example of rhmanifest::

    <?xml version="1.0"?>
    <rhmanifest>
      <repository root="/foo/bar">
        <manifest revision="1234" path="lib">
          <file name="diff.rb" revision="123" node="34567abc..." time="12345"
                 size="100"/>
          ...
          <dir name="redmine"/>
          ...
        </manifest>
      </repository>
    </rhmanifest>
"""
import re, time, cgi, urllib
from mercurial import cmdutil, commands, node, error

_x = cgi.escape
_u = lambda s: cgi.escape(urllib.quote(s))

def _tip(ui, repo):
    # see mercurial/commands.py:tip
    def tiprev():
        try:
            return len(repo) - 1
        except TypeError:  # Mercurial < 1.1
            return repo.changelog.count() - 1
    tipctx = repo.changectx(tiprev())
    ui.write('<tip revision="%d" node="%s"/>\n'
             % (tipctx.rev(), _x(node.short(tipctx.node()))))

_SPECIAL_TAGS = ('tip',)

def _tags(ui, repo):
    # see mercurial/commands.py:tags
    for t, n in reversed(repo.tagslist()):
        if t in _SPECIAL_TAGS:
            continue
        try:
            r = repo.changelog.rev(n)
        except error.LookupError:
            continue
        ui.write('<tag revision="%d" node="%s" name="%s"/>\n'
                 % (r, _x(node.short(n)), _x(t)))

def _branches(ui, repo):
    # see mercurial/commands.py:branches
    def iterbranches():
        for t, n in repo.branchtags().iteritems():
            yield t, n, repo.changelog.rev(n)
    def branchheads(branch):
        try:
            return repo.branchheads(branch, closed=False)
        except TypeError:  # Mercurial < 1.2
            return repo.branchheads(branch)
    for t, n, r in sorted(iterbranches(), key=lambda e: e[2], reverse=True):
        if repo.lookup(r) in branchheads(t):
            ui.write('<branch revision="%d" node="%s" name="%s"/>\n'
                     % (r, _x(node.short(n)), _x(t)))

def _manifest(ui, repo, path, rev):
    ctx = repo.changectx(rev)
    ui.write('<manifest revision="%d" path="%s">\n'
             % (ctx.rev(), _u(path)))

    known = set()
    pathprefix = (path.rstrip('/') + '/').lstrip('/')
    for f, n in sorted(ctx.manifest().iteritems(), key=lambda e: e[0]):
        if not f.startswith(pathprefix):
            continue
        name = re.sub(r'/.*', '/', f[len(pathprefix):])
        if name in known:
            continue
        known.add(name)

        if name.endswith('/'):
            ui.write('<dir name="%s"/>\n'
                     % _x(urllib.quote(name[:-1])))
        else:
            fctx = repo.filectx(f, fileid=n)
            tm, tzoffset = fctx.date()
            ui.write('<file name="%s" revision="%d" node="%s" '
                     'time="%d" size="%d"/>\n'
                     % (_u(name), fctx.rev(), _x(node.short(fctx.node())),
                        tm, fctx.size(), ))

    ui.write('</manifest>\n')

def rhannotate(ui, repo, *pats, **opts):
    return commands.annotate(ui, repo, *map(urllib.unquote_plus, pats), **opts)

def rhcat(ui, repo, file1, *pats, **opts):
    return commands.cat(ui, repo, urllib.unquote_plus(file1), *map(urllib.unquote_plus, pats), **opts)

def rhdiff(ui, repo, *pats, **opts):
    """diff repository (or selected files)"""
    change = opts.pop('change', None)
    if change:  # add -c option for Mercurial<1.1
        base = repo.changectx(change).parents()[0].rev()
        opts['rev'] = [str(base), change]
    opts['nodates'] = True
    return commands.diff(ui, repo, *map(urllib.unquote_plus, pats), **opts)

def rhmanifest(ui, repo, path='', **opts):
    """output the sub-manifest of the specified directory"""
    ui.write('<?xml version="1.0"?>\n')
    ui.write('<rhmanifest>\n')
    ui.write('<repository root="%s">\n' % _u(repo.root))
    try:
        _manifest(ui, repo, urllib.unquote_plus(path), opts.get('rev'))
    finally:
        ui.write('</repository>\n')
        ui.write('</rhmanifest>\n')

def rhsummary(ui, repo, **opts):
    """output the summary of the repository"""
    ui.write('<?xml version="1.0"?>\n')
    ui.write('<rhsummary>\n')
    ui.write('<repository root="%s">\n' % _u(repo.root))
    try:
        _tip(ui, repo)
        _tags(ui, repo)
        _branches(ui, repo)
        # TODO: bookmarks in core (Mercurial>=1.8)
    finally:
        ui.write('</repository>\n')
        ui.write('</rhsummary>\n')

# This extension should be compatible with Mercurial 0.9.5.
# Note that Mercurial 0.9.5 doesn't have extensions.wrapfunction().
cmdtable = {
    'rhannotate': (rhannotate,
         [('r', 'rev', '', 'revision'),
          ('u', 'user', None, 'list the author (long with -v)'),
          ('n', 'number', None, 'list the revision number (default)'),
          ('c', 'changeset', None, 'list the changeset'),
         ],
         'hg rhannotate [-r REV] [-u] [-n] [-c] FILE...'),
    'rhcat': (rhcat,
               [('r', 'rev', '', 'revision')],
               'hg rhcat ([-r REV] ...) FILE...'),
    'rhdiff': (rhdiff,
               [('r', 'rev', [], 'revision'),
                ('c', 'change', '', 'change made by revision')],
               'hg rhdiff ([-c REV] | [-r REV] ...) [FILE]...'),
    'rhmanifest': (rhmanifest,
                   [('r', 'rev', '', 'show the specified revision')],
                   'hg rhmanifest [-r REV] [PATH]'),
    'rhsummary': (rhsummary, [], 'hg rhsummary'),
}
