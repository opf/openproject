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
  has_many :changesets, :dependent => :destroy, :order => "#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC"
  has_many :changes, :through => :changesets
    
  def scm
    @scm ||= self.scm_adapter.new url, root_url, login, password
    update_attribute(:root_url, @scm.root_url) if root_url.blank?
    @scm
  end
  
  def scm_name
    self.class.scm_name
  end
  
  def supports_cat?
    scm.supports_cat?
  end

  def supports_annotate?
    scm.supports_annotate?
  end
  
  def entries(path=nil, identifier=nil)
    scm.entries(path, identifier)
  end
  
  def diff(path, rev, rev_to, type)
    scm.diff(path, rev, rev_to, type)
  end
  
  # Default behaviour: we search in cached changesets
  def changesets_for_path(path)
    path = "/#{path}" unless path.starts_with?('/')
    Change.find(:all, :include => :changeset, 
      :conditions => ["repository_id = ? AND path = ?", id, path],
      :order => "committed_on DESC, #{Changeset.table_name}.id DESC").collect(&:changeset)
  end
  
  def latest_changeset
    @latest_changeset ||= changesets.find(:first)
  end
    
  def scan_changesets_for_issue_ids
    self.changesets.each(&:scan_comment_for_issue_ids)
  end
  
  # fetch new changesets for all repositories
  # can be called periodically by an external script
  # eg. ruby script/runner "Repository.fetch_changesets"
  def self.fetch_changesets
    find(:all).each(&:fetch_changesets)
  end
  
  # scan changeset comments to find related and fixed issues for all repositories
  def self.scan_changesets_for_issue_ids
    find(:all).each(&:scan_changesets_for_issue_ids)
  end

  def self.scm_name
    'Abstract'
  end
  
  def self.available_scm
    subclasses.collect {|klass| [klass.scm_name, klass.name]}
  end
  
  def self.factory(klass_name, *args)
    klass = "Repository::#{klass_name}".constantize
    klass.new(*args)
  rescue
    nil
  end
end
