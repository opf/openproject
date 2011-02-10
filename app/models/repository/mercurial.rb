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

require 'redmine/scm/adapters/mercurial_adapter'

class Repository::Mercurial < Repository
  # sort changesets by revision number
  has_many :changesets, :order => "#{Changeset.table_name}.id DESC", :foreign_key => 'repository_id'

  attr_protected :root_url
  validates_presence_of :url

  def scm_adapter
    Redmine::Scm::Adapters::MercurialAdapter
  end

  def self.scm_name
    'Mercurial'
  end

  # Returns the readable identifier for the given mercurial changeset
  def self.format_changeset_identifier(changeset)
    "#{changeset.revision}:#{changeset.scmid}"
  end

  # Returns the identifier for the given Mercurial changeset
  def self.changeset_identifier(changeset)
    changeset.scmid
  end

  def diff_format_revisions(cs, cs_to, sep=':')
    super(cs, cs_to, ' ')
  end

  def entries(path=nil, identifier=nil)
    entries=scm.entries(path, identifier)
    if entries
      entries.each do |entry|
        next unless entry.is_file?
        # Set the filesize unless browsing a specific revision
        if identifier.nil?
          full_path = File.join(root_url, entry.path)
          entry.size = File.stat(full_path).size if File.file?(full_path)
        end
        # Search the DB for the entry's last change
        change = changes.find(:first, :conditions => ["path = ?", scm.with_leading_slash(entry.path)], :order => "#{Changeset.table_name}.committed_on DESC")
        if change
          entry.lastrev.identifier = change.changeset.revision
          entry.lastrev.name = change.changeset.revision
          entry.lastrev.author = change.changeset.committer
          entry.lastrev.revision = change.revision
        end
      end
    end
    entries
  end

  # Finds and returns a revision with a number or the beginning of a hash
  def find_changeset_by_name(name)
    return nil if name.nil? || name.empty?
    if /[^\d]/ =~ name or name.to_s.size > 8
      e = changesets.find(:first, :conditions => ['scmid = ?', name.to_s])
    else
      e = changesets.find(:first, :conditions => ['revision = ?', name.to_s])
    end
    return e if e
    changesets.find(:first, :conditions => ['scmid LIKE ?', "#{name}%"])  # last ditch
  end

  # Returns the latest changesets for +path+; sorted by revision number
  def latest_changesets(path, rev, limit=10)
    if path.blank?
      changesets.find(:all, :include => :user, :limit => limit)
    else
      changes.find(:all, :include => {:changeset => :user},
                         :conditions => ["path = ?", path.with_leading_slash],
                         :order => "#{Changeset.table_name}.id DESC",
                         :limit => limit).collect(&:changeset)
    end
  end

  def fetch_changesets
    scm_info = scm.info
    if scm_info
      # latest revision found in database
      db_revision = latest_changeset ? latest_changeset.revision.to_i : -1
      # latest revision in the repository
      latest_revision = scm_info.lastrev
      return if latest_revision.nil?
      scm_revision = latest_revision.identifier.to_i
      if db_revision < scm_revision
        logger.debug "Fetching changesets for repository #{url}" if logger && logger.debug?
        identifier_from = db_revision + 1
        while (identifier_from <= scm_revision)
          # loads changesets by batches of 100
          identifier_to = [identifier_from + 99, scm_revision].min
          revisions = scm.revisions('', identifier_from, identifier_to, :with_paths => true)
          transaction do
            revisions.each do |revision|
              changeset = Changeset.create(:repository => self,
                                           :revision => revision.identifier,
                                           :scmid => revision.scmid,
                                           :committer => revision.author, 
                                           :committed_on => revision.time,
                                           :comments => revision.message)
              
              revision.paths.each do |change|
                changeset.create_change(change)
              end
            end
          end unless revisions.nil?
          identifier_from = identifier_to + 1
        end
      end
    end
  end
end
