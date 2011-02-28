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
  include Redmine::Ciphering
  
  belongs_to :project
  has_many :changesets, :order => "#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC"
  has_many :changes, :through => :changesets
  
  # Raw SQL to delete changesets and changes in the database
  # has_many :changesets, :dependent => :destroy is too slow for big repositories
  before_destroy :clear_changesets
  
  validates_length_of :password, :maximum => 255, :allow_nil => true
  # Checks if the SCM is enabled when creating a repository
  validate_on_create { |r| r.errors.add(:type, :invalid) unless Setting.enabled_scm.include?(r.class.name.demodulize) }

  # Removes leading and trailing whitespace
  def url=(arg)
    write_attribute(:url, arg ? arg.to_s.strip : nil)
  end

  # Removes leading and trailing whitespace
  def root_url=(arg)
    write_attribute(:root_url, arg ? arg.to_s.strip : nil)
  end
  
  def password
    read_ciphered_attribute(:password)
  end
  
  def password=(arg)
    write_ciphered_attribute(:password, arg)
  end

  def scm_adapter
    self.class.scm_adapter_class
  end

  def scm
    @scm ||= self.scm_adapter.new(url, root_url,
                                  login, password, path_encoding)
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

  def branches
    scm.branches
  end

  def tags
    scm.tags
  end

  def default_branch
    scm.default_branch
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

  def diff_format_revisions(cs, cs_to, sep=':')
    text = ""
    text << cs_to.format_identifier + sep if cs_to
    text << cs.format_identifier if cs
    text
  end

  # Returns a path relative to the url of the repository
  def relative_path(path)
    path
  end

  # Finds and returns a revision with a number or the beginning of a hash
  def find_changeset_by_name(name)
    return nil if name.blank?
    changesets.find(:first, :conditions => (name.match(/^\d*$/) ? ["revision = ?", name.to_s] : ["revision LIKE ?", name + '%']))
  end

  def latest_changeset
    @latest_changeset ||= changesets.find(:first)
  end

  # Returns the latest changesets for +path+
  # Default behaviour is to search in cached changesets
  def latest_changesets(path, rev, limit=10)
    if path.blank?
      changesets.find(:all, :include => :user,
                            :order => "#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC",
                            :limit => limit)
    else
      changes.find(:all, :include => {:changeset => :user}, 
                         :conditions => ["path = ?", path.with_leading_slash],
                         :order => "#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC",
                         :limit => limit).collect(&:changeset)
    end
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
      @found_committer_users = nil
      true
    else
      false
    end
  end
  
  # Returns the Redmine User corresponding to the given +committer+
  # It will return nil if the committer is not yet mapped and if no User
  # with the same username or email was found
  def find_committer_user(committer)
    unless committer.blank?
      @found_committer_users ||= {}
      return @found_committer_users[committer] if @found_committer_users.has_key?(committer)
      
      user = nil
      c = changesets.find(:first, :conditions => {:committer => committer}, :include => :user)
      if c && c.user
        user = c.user
      elsif committer.strip =~ /^([^<]+)(<(.*)>)?$/
        username, email = $1.strip, $3
        u = User.find_by_login(username)
        u ||= User.find_by_mail(email) unless email.blank?
        user = u
      end
      @found_committer_users[committer] = user
      user
    end
  end

  def repo_log_encoding
    encoding = Setting.commit_logs_encoding.to_s.strip
    encoding.blank? ? 'UTF-8' : encoding
  end

  # Fetches new changesets for all repositories of active projects
  # Can be called periodically by an external script
  # eg. ruby script/runner "Repository.fetch_changesets"
  def self.fetch_changesets
    Project.active.has_module(:repository).find(:all, :include => :repository).each do |project|
      if project.repository
        begin
          project.repository.fetch_changesets
        rescue Redmine::Scm::Adapters::CommandFailed => e
          logger.error "scm: error during fetching changesets: #{e.message}"
        end
      end
    end
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

  def self.scm_adapter_class
    nil
  end

  def self.scm_command
    ret = ""
    begin
      ret = self.scm_adapter_class.client_command if self.scm_adapter_class
    rescue Redmine::Scm::Adapters::CommandFailed => e
      logger.error "scm: error during get command: #{e.message}"
    end
    ret
  end

  def self.scm_version_string
    ret = ""
    begin
      ret = self.scm_adapter_class.client_version_string if self.scm_adapter_class
    rescue Redmine::Scm::Adapters::CommandFailed => e
      logger.error "scm: error during get version string: #{e.message}"
    end
    ret
  end

  def self.scm_available
    ret = false
    begin
      ret = self.scm_adapter_class.client_available if self.scm_adapter_class 
    rescue Redmine::Scm::Adapters::CommandFailed => e
      logger.error "scm: error during get scm available: #{e.message}"
    end
    ret
  end

  private

  def before_save
    # Strips url and root_url
    url.strip!
    root_url.strip!
    true
  end
  
  def clear_changesets
    cs, ch, ci = Changeset.table_name, Change.table_name, "#{table_name_prefix}changesets_issues#{table_name_suffix}"
    connection.delete("DELETE FROM #{ch} WHERE #{ch}.changeset_id IN (SELECT #{cs}.id FROM #{cs} WHERE #{cs}.repository_id = #{id})")
    connection.delete("DELETE FROM #{ci} WHERE #{ci}.changeset_id IN (SELECT #{cs}.id FROM #{cs} WHERE #{cs}.repository_id = #{id})")
    connection.delete("DELETE FROM #{cs} WHERE #{cs}.repository_id = #{id}")
  end
end
