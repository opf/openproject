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

  ATTRIBUTE_KEY_NAMES = {
      "url"          => "Path to repository",
    }
  def self.human_attribute_name(attribute_key_name)
    ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
  end

  def self.scm_adapter_class
    Redmine::Scm::Adapters::GitAdapter
  end

  def self.scm_name
    'Git'
  end

  def repo_log_encoding
    'UTF-8'
  end

  # Returns the identifier for the given git changeset
  def self.changeset_identifier(changeset)
    changeset.scmid
  end

  # Returns the readable identifier for the given git changeset
  def self.format_changeset_identifier(changeset)
    changeset.revision[0, 8]
  end

  def branches
    scm.branches
  end

  def tags
    scm.tags
  end

  def find_changeset_by_name(name)
    return nil if name.nil? || name.empty?
    e = changesets.find(:first, :conditions => ['revision = ?', name.to_s])
    return e if e
    changesets.find(:first, :conditions => ['scmid LIKE ?', "#{name}%"])
  end

  # With SCM's that have a sequential commit numbering, redmine is able to be
  # clever and only fetch changesets going forward from the most recent one
  # it knows about.  However, with git, you never know if people have merged
  # commits into the middle of the repository history, so we should parse
  # the entire log. Since it's way too slow for large repositories, we only
  # parse 1 week before the last known commit.
  # The repository can still be fully reloaded by calling #clear_changesets
  # before fetching changesets (eg. for offline resync)
  def fetch_changesets
    c = changesets.find(:first, :order => 'committed_on DESC')
    since = (c ? c.committed_on - 7.days : nil)

    revisions = scm.revisions('', nil, nil, :all => true, :since => since)
    return if revisions.nil? || revisions.empty?

    recent_changesets = changesets.find(:all, :conditions => ['committed_on >= ?', since])

    # Clean out revisions that are no longer in git
    recent_changesets.each {|c| c.destroy unless revisions.detect {|r| r.scmid.to_s == c.scmid.to_s }}

    # Subtract revisions that redmine already knows about
    recent_revisions = recent_changesets.map{|c| c.scmid}
    revisions.reject!{|r| recent_revisions.include?(r.scmid)}

    # Save the remaining ones to the database
    unless revisions.nil?
      revisions.each do |rev|
        transaction do
          changeset = Changeset.new(
              :repository => self,
              :revision   => rev.identifier,
              :scmid      => rev.scmid,
              :committer  => rev.author, 
              :committed_on => rev.time,
              :comments   => rev.message)
            
          if changeset.save
            rev.paths.each do |file|
              Change.create(
                  :changeset => changeset,
                  :action    => file[:action],
                  :path      => file[:path])
            end
          end
        end
      end
    end
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
