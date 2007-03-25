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

class Repository < ActiveRecord::Base
  belongs_to :project
  has_many :changesets, :dependent => :destroy, :order => 'revision DESC'
  has_many :changes, :through => :changesets
  has_one  :latest_changeset, :class_name => 'Changeset', :foreign_key => :repository_id, :order => 'revision DESC'
  
  attr_protected :root_url
  
  validates_presence_of :url
  validates_format_of :url, :with => /^(http|https|svn|file):\/\/.+/i
    
  def scm
    @scm ||= SvnRepos::Base.new url, root_url, login, password
    update_attribute(:root_url, @scm.root_url) if root_url.blank?
    @scm
  end
  
  def url=(str)
    super if root_url.blank?
  end
  
  def changesets_for_path(path="")
    path = "/#{path}%"
    path = url.gsub(/^#{root_url}/, '') + path if root_url && root_url != url
    path.squeeze!("/")
    changesets.find(:all, :include => :changes,
                          :conditions => ["#{Change.table_name}.path LIKE ?", path])
  end
  
  def fetch_changesets
    scm_info = scm.info
    if scm_info
      lastrev_identifier = scm_info.lastrev.identifier.to_i
      if latest_changeset.nil? || latest_changeset.revision < lastrev_identifier
        logger.debug "Fetching changesets for repository #{url}" if logger && logger.debug?
        identifier_from = latest_changeset ? latest_changeset.revision + 1 : 1
        while (identifier_from <= lastrev_identifier)
          # loads changesets by batches of 200
          identifier_to = [identifier_from + 199, lastrev_identifier].min
          revisions = scm.revisions('', identifier_to, identifier_from, :with_paths => true)
          transaction do
            revisions.reverse_each do |revision|
              changeset = Changeset.create(:repository => self,
                                           :revision => revision.identifier, 
                                           :committer => revision.author, 
                                           :committed_on => revision.time,
                                           :comment => revision.message)
              
              revision.paths.each do |change|
                Change.create(:changeset => changeset,
                              :action => change[:action],
                              :path => change[:path],
                              :from_path => change[:from_path],
                              :from_revision => change[:from_revision])
              end
            end
          end
          identifier_from = identifier_to + 1
        end
      end
    end
  end
  
  # fetch new changesets for all repositories
  # can be called periodically by an external script
  # eg. ruby script/runner "Repository.fetch_changesets"
  def self.fetch_changesets
    find(:all).each(&:fetch_changesets)
  end
end
