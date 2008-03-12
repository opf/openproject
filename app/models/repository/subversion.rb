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

require 'redmine/scm/adapters/subversion_adapter'

class Repository::Subversion < Repository
  attr_protected :root_url
  validates_presence_of :url
  validates_format_of :url, :with => /^(http|https|svn|svn\+ssh|file):\/\/.+/i

  def scm_adapter
    Redmine::Scm::Adapters::SubversionAdapter
  end
  
  def self.scm_name
    'Subversion'
  end

  def changesets_for_path(path)
    revisions = scm.revisions(path)
    revisions ? changesets.find_all_by_revision(revisions.collect(&:identifier), :order => "committed_on DESC") : []
  end
  
  def fetch_changesets
    scm_info = scm.info
    if scm_info
      # latest revision found in database
      db_revision = latest_changeset ? latest_changeset.revision.to_i : 0
      # latest revision in the repository
      scm_revision = scm_info.lastrev.identifier.to_i
      if db_revision < scm_revision
        logger.debug "Fetching changesets for repository #{url}" if logger && logger.debug?
        identifier_from = db_revision + 1
        while (identifier_from <= scm_revision)
          # loads changesets by batches of 200
          identifier_to = [identifier_from + 199, scm_revision].min
          revisions = scm.revisions('', identifier_to, identifier_from, :with_paths => true)
          transaction do
            revisions.reverse_each do |revision|
              changeset = Changeset.create(:repository => self,
                                           :revision => revision.identifier, 
                                           :committer => revision.author, 
                                           :committed_on => revision.time,
                                           :comments => revision.message)
              
              revision.paths.each do |change|
                Change.create(:changeset => changeset,
                              :action => change[:action],
                              :path => change[:path],
                              :from_path => change[:from_path],
                              :from_revision => change[:from_revision])
              end
            end
          end unless revisions.nil?
          identifier_from = identifier_to + 1
        end
      end
    end
  end
end
