# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'redmine/scm/adapters/cvs_adapter'
require 'digest/sha1'

class Repository::Cvs < Repository
  validates_presence_of :url, :root_url

  def scm_adapter
    Redmine::Scm::Adapters::CvsAdapter
  end
  
  def self.scm_name
    'CVS'
  end
  
  def entry(path, identifier)
    e = entries(path, identifier)
    e ? e.first : nil
  end
  
  def entries(path=nil, identifier=nil)
    entries=scm.entries(path, identifier)
    if entries
      entries.each() do |entry|
        unless entry.lastrev.nil? || entry.lastrev.identifier
          change=changes.find_by_revision_and_path( entry.lastrev.revision, scm.with_leading_slash(entry.path) )
          if change
            entry.lastrev.identifier=change.changeset.revision
            entry.lastrev.author=change.changeset.committer
            entry.lastrev.revision=change.revision
            entry.lastrev.branch=change.branch
          end
        end
      end
    end
    entries
  end
  
  def diff(path, rev, rev_to, type)
    #convert rev to revision. CVS can't handle changesets here
    diff=[]
    changeset_from=changesets.find_by_revision(rev)
    if rev_to.to_i > 0 
      changeset_to=changesets.find_by_revision(rev_to)
    end
    changeset_from.changes.each() do |change_from|
      
      revision_from=nil
      revision_to=nil      
      
      revision_from=change_from.revision if path.nil? || (change_from.path.starts_with? scm.with_leading_slash(path))
      
      if revision_from
        if changeset_to
          changeset_to.changes.each() do |change_to|
            revision_to=change_to.revision if change_to.path==change_from.path 
          end
        end
        unless revision_to
          revision_to=scm.get_previous_revision(revision_from)
        end
        diff=diff+scm.diff(change_from.path, revision_from, revision_to, type)
      end
    end
    return diff
  end
  
  def fetch_changesets
    # some nifty bits to introduce a commit-id with cvs
    # natively cvs doesn't provide any kind of changesets, there is only a revision per file.
    # we now take a guess using the author, the commitlog and the commit-date.
    
    # last one is the next step to take. the commit-date is not equal for all 
    # commits in one changeset. cvs update the commit-date when the *,v file was touched. so
    # we use a small delta here, to merge all changes belonging to _one_ changeset
    time_delta=10.seconds
    
    fetch_since = latest_changeset ? latest_changeset.committed_on : nil
    transaction do
      tmp_rev_num = 1
      scm.revisions('', fetch_since, nil, :with_paths => true) do |revision|
        # only add the change to the database, if it doen't exists. the cvs log
        # is not exclusive at all. 
        unless changes.find_by_path_and_revision(scm.with_leading_slash(revision.paths[0][:path]), revision.paths[0][:revision])
          revision
          cs = changesets.find(:first, :conditions=>{
            :committed_on=>revision.time-time_delta..revision.time+time_delta,
            :committer=>revision.author,
            :comments=>revision.message
          })
        
          # create a new changeset.... 
          unless cs
            # we use a temporaray revision number here (just for inserting)
            # later on, we calculate a continous positive number
            latest = changesets.find(:first, :order => 'id DESC')
            cs = Changeset.create(:repository => self,
                                  :revision => "_#{tmp_rev_num}", 
                                  :committer => revision.author, 
                                  :committed_on => revision.time,
                                  :comments => revision.message)
            tmp_rev_num += 1
          end
        
          #convert CVS-File-States to internal Action-abbrevations
          #default action is (M)odified
          action="M"
          if revision.paths[0][:action]=="Exp" && revision.paths[0][:revision]=="1.1"
            action="A" #add-action always at first revision (= 1.1)
          elsif revision.paths[0][:action]=="dead"
            action="D" #dead-state is similar to Delete
          end
        
          Change.create(:changeset => cs,
          :action => action,
          :path => scm.with_leading_slash(revision.paths[0][:path]),
          :revision => revision.paths[0][:revision],
          :branch => revision.paths[0][:branch]
          )
        end
      end
      
      # Renumber new changesets in chronological order
      c = changesets.find(:first, :order => 'committed_on DESC, id DESC', :conditions => "revision NOT LIKE '_%'")
      next_rev = c.nil? ? 1 : (c.revision.to_i + 1)
      changesets.find(:all, :order => 'committed_on ASC, id ASC', :conditions => "revision LIKE '_%'").each do |changeset|
        changeset.update_attribute :revision, next_rev
        next_rev += 1
      end
    end # transaction
  end
end
