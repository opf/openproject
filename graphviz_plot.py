#!/usr/bin/python
#emacs: -*- mode: python-mode; py-indent-offset: 4; tab-width: 4; indent-tabs-mode: t -*- 
#ex: set sts=4 ts=4 sw=4 noet:
#------------------------- =+- Python script -+= -------------------------
"""
 @file      graphviz_plot.py
 @date      Mon Aug 11 11:54:34 2008
 @brief


  Yaroslav Halchenko                                      CS@UNM, CS@NJIT
  web:     http://www.onerussian.com                      & PSYCH@RUTGERS
  e-mail:  yoh@onerussian.com                              ICQ#: 60653192

 DESCRIPTION (NOTES): Prototype code to draw using graphviz a git
   history of merges with collapses, where plain 1-parent 1-child
   commits occured

   TODO:
    use pydot internally to create a graph
	proper filenames specification
	....

   EXAMPLE USAGE:

   ../graphviz_plot.py --all # will generate graph.dot
   dot -Tsvg graph.dot >| graph.svg
   inkscape graph.svg

 COPYRIGHT: Yaroslav Halchenko 2008

 LICENSE:

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the 
  Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
  MA 02110-1301, USA.

 On Debian system see /usr/share/common-licenses/GPL for the full license.
"""
#-----------------\____________________________________/------------------

__author__ = 'Yaroslav Halhenko'
__revision__ = '$Revision: $'
__date__ = '$Date:  $'
__copyright__ = 'Copyright (c) 2008 Yaroslav Halchenko'
__license__ = 'GPL'


import sys, re, os

gitargs = ' '.join(sys.argv[1:])

# lets read all commits and place into list
commits = []

split_strip = lambda f, split_symbol: [[x.strip() for x in l.split(split_symbol)]
									   for l in f.readlines()]

print "I: Reading the commits"
f = os.popen('git rev-list --pretty=format:"%%H|%%h|%%an|%%s" "%s" | grep -v "^commit"'
					% gitargs)
commits = split_strip(f, '|')

print "I: Reading the tree"
f = os.popen('git rev-list --parents "%s"' % gitargs)
tree_down = split_strip(f, ' ')


print "I: Reading heads"
f = os.popen("git branch --no-color -v --no-abbrev | sed -e 's,\*,,g' | awk '{print $1, $2;}'")
heads_list = split_strip(f, ' ')
heads_dict = dict( [ (y,x) for x,y in heads_list ] )


# need to traverse the tree and create double linked nodes instead of
# just parent since we would need to remove some
tree = dict([(n[0], [n[1:], [], [], [], []]) for n in tree_down])

print "I: Rebuilding childrens"
# lets rebuild children nodes -- may be there is cleaner way? :-)
for id_, (parents, children, indirect_parents, cherried_into, cherried_from) in tree.iteritems():
	for parent in parents:
		tree[parent][1].append(id_)

print "I: Figuring out cherry picks"
# following evil bash line gives what is needed
# git rev-list --no-merges --pretty=format:"|%H|%h|%ci|%an|%ae|%s|%b|" --all | grep -v '^commit' | tr '&' '%' | tr '\n' '&' | sed -e 's/|&/|\n/g' -e 's/&|/|/g' |  sort -t\| -k 5,8  | uniq -d -s75 -D | while read commit; do sha=$(echo $commit | awk -F\| '{print $2;}'); diffsha=$(git diff ${sha}^..${sha} | grep '^[+-]' | sha1sum | awk '{print $1;}'); echo "$commit|$diffsha"; done  |  sort -t\| -k 5,10 | uniq -d -s75 -D
#
# in summary it does
#  1. list all non merge commits and looks for similar according
#  to author/commit_msg
#
#  2. since some times commit_msg's are bogus -- we also add sha1sum for
#  changed context by that commit -- lines which start with + or -
#
#  3. and then once again - sort and uniq ;-)
#
# result looks like
# |072c0f7a0449130e7363be9ef618668147ece87e|072c0f7|2008-07-30 18:26:26 +0200|Julian_chu|julian_chu@openmoko.com|[splinter] Bump up the reversion of splinter to 507|For some UI tunning stuff||66e879ca796685319d4602487e0e52c629217191
# |23ed84fc72097e7abe1dac21453a33ce9440991d|23ed84f|2008-07-30 23:01:44 +0800|Julian_chu|julian_chu@openmoko.com|[splinter] Bump up the reversion of splinter to 507|For some UI tunning stuff||66e879ca796685319d4602487e0e52c629217191
# |8c1e9ae76bf39c141d2f5bdc759c5fb628574463|8c1e9ae|2008-05-11 23:32:35 +0000||julian_chu@openmoko.com|Add Ninja Theme as default|||8f42ba37c6fef619bf922a689d560e0ffc979b5f
# |ac9d16ad220468ba1f359355e155e2dc2a232272|ac9d16a|2008-05-25 22:27:39 +0800||julian_chu@openmoko.com|Add Ninja Theme as default|||8f42ba37c6fef619bf922a689d560e0ffc979b5f
#
# so we just need to compare the times to derive from where it was cherry picked
cmd = 'git rev-list --no-merges --pretty=format:"|%%H|%%h|%%ci|%%an|%%ae|%%s|%%b|" %s | grep -v "^commit" | tr "&" "%%" | tr "\\n" "&" | sed -e "s/|&/|\\n/g" -e "s/&|/|/g" |  sort -t\| -k 5,8  | uniq -d -s75 -D | while read commit; do sha=$(echo $commit | awk -F\| "{print \$2;}"); diffsha=$(git diff ${sha}^..${sha} | grep "^[+-]" | sha1sum | awk "{print \$1;}"); echo "$commit|$diffsha"; done  |  sort -t\| -k 5,10 | uniq -d -s75 -D' % gitargs
f = os.popen(cmd)
cherry_picks_raw = split_strip(f, '|')
#print cherry_picks_raw

print "I: Analyzing cherry picks"
# 3 - date
# >=4 -- use for id
cp_uid_last = None
cp_date_min = 'X'
cherry_picks = {}
cp_ids = []
for cp in cherry_picks_raw + [ [' ']*12 ]: # trailer for easier logic
	id_ = cp[1]
	cp_date = cp[3]
	cp_uid = ' '.join(cp[4:])
	if cp_uid_last != cp_uid and cp_uid_last is not None:
		# process it since we got to a new one
		#print "D: Process cherry pick '%s' created in %s" % (cp_uid_last, id_min)
		try:
			cp_ids.pop(cp_ids.index(id_min))
		except:
			# XXX should not happen but does -- figure out later
			pass
		tree[id_min][3] = cp_ids
		for cp_ in cp_ids:
			tree[cp_][4] = [id_min]
		cp_ids = []
		pass
	if cp_date < cp_date_min:
		cp_date_min = cp_date
		id_min = id_
	cp_uid_last = cp_uid
	cp_ids.append(id_)
assert(id_ == ' ')


print "I: Figuring out branches ownership from merge messages"
# for now each node belongs just to 1 branch although sure thing it
# could be in few branches at that moment
regexp = re.compile("Merge (?P<type>branch|commit) '(?P<branch0>.*)'(?: into (?P<branch1>[^. ,|]*))?")
branches = {}
for commit in commits:
	fid = commit[0]
	# only those which are left
	if not fid in tree:
		continue
	comment = commit[3]
	regres = regexp.search(comment)
	if regres is None:
		# print "I: don't know branch for %s" % fid
		continue

	regdict = regres.groupdict()

	if regdict['branch1'] == None:
		regdict['branch1'] = 'master'

	branches[fid] = regdict['branch1']
	# TODO check what is message with octopus
	if regdict['type'] == 'branch':
		#import pydb
		#pydb.debugger()
		branches[ tree[fid][0][1] ] = regdict['branch0']
		branches[ tree[fid][0][0] ] = regdict['branch1']

from sets import Set
branches_names = list(Set(branches.values() + heads_dict.values()))
print "D: Detected branches from merges: ", branches_names
branches_colors = dict([[x, i+2] for i,x in enumerate(branches_names)])
#print branches_colors

#for k, p in tree.iteritems():
#	print k, p

print "I: Pruning"
# lets go through all nodes and if there is only 1 parent and 1 child -- KILL!!!
for id_ in tree.keys():
	parents, children, indirect_parents, cherried_into, cherried_from = tree[id_]
	if len(children) == 1 and len(parents) + len(indirect_parents) == 1 \
	   and len(cherried_into) + len(cherried_from) == 0 \
	   and (not id_ in heads_dict):# and False:
		# print "D: %s with %s" % (id_, tree[id_])
		tree.pop(id_)

		# update children
		for child in children:
			tchild = tree[child]
			tchild[2] += parents + indirect_parents
			for i in [0,2]:
				try:
					tchild[i].pop(tchild[i].index(id_))
					#print "removed %s from %s's parent %d" % (id_, child, i)
				except:
					pass

		# update the parent
		for parent in parents + indirect_parents:
			tparent = tree[parent]
			tparent[1] += children
			try:
				tparent[1].pop(tparent[1].index(id_))
				#print "removed %s from %s's children" % (id_, parent)
			except:
				pass


#print tree
print "I: Storing graph"
# plot the damn graph ;-)
fout = open('graph.dot', 'w')
fout.write("digraph lattice {\n")

# print nodes
for commit in commits:
	fid = commit[0]
	# only those which are left
	if not fid in tree:
		continue

	sid = commit[1]
	if len(commit)>2:
		comment = ' '.join(commit[3:])
	else:
		comment = ''

	# condition comment
	comment = comment.replace('"', "'")[:60]

	try:
		color = ", fillcolor=\"/brbg11/%s\", style=\"filled\"" % branches_colors[branches[fid]]
	except:
		color = ""

	fout.write('n%s [ label="%s\\n%s"%s]\n' % (fid, sid, comment, color))

# print heads
for head_id, head_name in heads_dict.iteritems():
	try:
		color = ", color=\"/brbg11/%s\", style=\"filled\"" % branches_colors[head_name]
	except:
		color = ""
	fout.write('h%s [ shape=box, label="%s"%s]\n' % (head_id, head_name, color))

# print edges
for id_, (parents, children, indirect_parents, cherried_into, cherried_from) in tree.iteritems():
	c = ("", " [ color=\"red\"]")[int(len(parents)>1)]

	for p in parents:
		fout.write("n%s -> n%s%s\n" % (id_, p, c))

	for p in indirect_parents:
		fout.write("n%s -> n%s [style=dashed, color=\"red\"]\n" % (id_, p))

	if len(cherried_from)>0:
		fout.write("n%s -> n%s [style=dashed]\n" % (id_, cherried_from[0]))

# print links from heads
for head_id, head_name in heads_dict.iteritems():
	fout.write("h%s -> n%s\n" % (head_id, head_id))

fout.write("}\n")
fout.close()
