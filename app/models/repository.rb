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
  has_many :changesets, :order => "#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC"
  has_many :changes, :through => :changesets
  
  # Raw SQL to delete changesets and changes in the database
  # has_many :changesets, :dependent => :destroy is too slow for big repositories
  before_destroy :clear_changesets
  
  # Checks if the SCM is enabled when creating a repository
  validate_on_create { |r| r.errors.add(:type, :activerecord_error_invalid) unless Setting.enabled_scm.include?(r.class.name.demodulize) }
  
  # Removes leading and trailing whitespace
  def url=(arg)
    write_attribute(:url, arg ? arg.to_s.strip : nil)
  end
  
  # Removes leading and trailing whitespace
  def root_url=(arg)
    write_attribute(:root_url, arg ? arg.to_s.strip : nil)
  end

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
  
  def entry(path=nil, identifier=nil)
    scm.entry(path, identifier)
  end
  
  def entries(path=nil, identifier=nil)
    scm.entries(path, identifier)
  end
  
  def properties(path, identifier=nil)
    scm.properties(path, identifier)
  end
  
  def cat(path, identifier=nil)
    scm.cat(path, identifier)
  end
  
  def diff(path, rev, rev_to)
    scm.diff(path, rev, rev_to)
  end
  
  # Default behaviour: we search in cached changesets
  def changesets_for_path(path)
    path = "/#{path}" unless path.starts_with?('/')
    Change.find(:all, :include => {:changeset => :user}, 
      :conditions => ["repository_id = ? AND path = ?", id, path],
      :order => "committed_on DESC, #{Changeset.table_name}.id DESC").collect(&:changeset)
  end
  
  # Returns a path relative to the url of the repository
  def relative_path(path)
    path
  end
  
  def latest_changeset
    @latest_changeset ||= changesets.find(:first)
  end
    
  def scan_changesets_for_issue_ids
    self.changesets.each(&:scan_comment_for_issue_ids)
  end
  
  # Returns an array of committers usernames and associated user_id
  def committers
    @committers ||= Changeset.connection.select_rows("SELECT DISTINCT committer, user_id FROM #{Changeset.table_name} WHERE repository_id = #{id}")
  end
  
  # Maps committers username to a user ids
  def committer_ids=(h)
    if h.is_a?(Hash)
      committers.each do |committer, user_id|
        new_user_id = h[committer]
        if new_user_id && (new_user_id.to_i != user_id.to_i)
          new_user_id = (new_user_id.to_i > 0 ? new_user_id.to_i : nil)
          Changeset.update_all("user_id = #{ new_user_id.nil? ? 'NULL' : new_user_id }", ["repository_id = ? AND committer = ?", id, committer])
        end
      end
      @committers = nil
      true
    else
      false
    end
  end
  
  # Returns the Redmine User corresponding to the given +committer+
  # It will return nil if the committer is not yet mapped and if no User
  # with the same username or email was found
  def find_committer_user(committer)
    if committer
      c = changesets.find(:first, :conditions => {:committer => committer}, :include => :user)
      if c && c.user
        c.user
      elsif committer.strip =~ /^([^<]+)(<(.*)>)?$/
        username, email = $1.strip, $3
        u = User.find_by_login(username)
        u ||= User.find_by_mail(email) unless email.blank?
        u
      end
    end
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
  
  private
  
  def before_save
    # Strips url and root_url
    url.strip!
    root_url.strip!
    true
  end
  
  def clear_changesets
    connection.delete("DELETE FROM changes WHERE changes.changeset_id IN (SELECT changesets.id FROM changesets WHERE changesets.repository_id = #{id})")
    connection.delete("DELETE FROM changesets_issues WHERE changesets_issues.changeset_id IN (SELECT changesets.id FROM changesets WHERE changesets.repository_id = #{id})")
    connection.delete("DELETE FROM changesets WHERE changesets.repository_id = #{id}")
  end
end
