# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
# Copyright (C) 2007  Patrick Aljord patcito@ŋmail.com
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

require 'redmine/scm/adapters/git_adapter'

class Repository::Git < Repository
  attr_protected :root_url
  validates_presence_of :url

  def scm_adapter
    Redmine::Scm::Adapters::GitAdapter
  end
  
  def self.scm_name
    'Git'
  end

  def branches
    scm.branches
  end

  def tags
    scm.tags
  end

  def changesets_for_path(path, options={})
    Change.find(
      :all, 
      :include => {:changeset => :user}, 
      :conditions => ["repository_id = ? AND path = ?", id, path],
      :order => "committed_on DESC, #{Changeset.table_name}.revision DESC",
      :limit => options[:limit]
    ).collect(&:changeset)
  end

  # With SCM's that have a sequential commit numbering, redmine is able to be
  # clever and only fetch changesets going forward from the most recent one
  # it knows about.  However, with git, you never know if people have merged
  # commits into the middle of the repository history, so we always have to
  # parse the entire log.
  def fetch_changesets
    # Save ourselves an expensive operation if we're already up to date
    return if scm.num_revisions == changesets.count

    revisions = scm.revisions('', nil, nil, :all => true)
    return if revisions.nil? || revisions.empty?

    # Find revisions that redmine knows about already
    existing_revisions = changesets.find(:all).map!{|c| c.scmid}

    # Clean out revisions that are no longer in git
    Changeset.delete_all(["scmid NOT IN (?) AND repository_id = (?)", revisions.map{|r| r.scmid}, self.id])

    # Subtract revisions that redmine already knows about
    revisions.reject!{|r| existing_revisions.include?(r.scmid)}

    # Save the remaining ones to the database
    revisions.each{|r| r.save(self)} unless revisions.nil?
  end

  def latest_changesets(path,rev,limit=10)
    revisions = scm.revisions(path, nil, rev, :limit => limit, :all => false)
    return [] if revisions.nil? || revisions.empty?

    changesets.find(
      :all, 
      :conditions => [
        "scmid IN (?)", 
        revisions.map!{|c| c.scmid}
      ],
      :order => 'committed_on DESC'
    )
  end
end
