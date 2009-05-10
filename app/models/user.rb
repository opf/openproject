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

require "digest/sha1"

class User < ActiveRecord::Base

  # Account statuses
  STATUS_ANONYMOUS  = 0
  STATUS_ACTIVE     = 1
  STATUS_REGISTERED = 2
  STATUS_LOCKED     = 3
  
  USER_FORMATS = {
    :firstname_lastname => '#{firstname} #{lastname}',
    :firstname => '#{firstname}',
    :lastname_firstname => '#{lastname} #{firstname}',
    :lastname_coma_firstname => '#{lastname}, #{firstname}',
    :username => '#{login}'
  }

  has_many :memberships, :class_name => 'Member', :include => [ :project, :roles ], :conditions => "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}", :order => "#{Project.table_name}.name"
  has_many :members, :dependent => :delete_all
  has_many :projects, :through => :memberships
  has_many :issue_categories, :foreign_key => 'assigned_to_id', :dependent => :nullify
  has_many :changesets, :dependent => :nullify
  has_one :preference, :dependent => :destroy, :class_name => 'UserPreference'
  has_one :rss_token, :dependent => :destroy, :class_name => 'Token', :conditions => "action='feeds'"
  belongs_to :auth_source
  
  # Active non-anonymous users scope
  named_scope :active, :conditions => "#{User.table_name}.status = #{STATUS_ACTIVE}"
  
  acts_as_customizable
  
  attr_accessor :password, :password_confirmation
  attr_accessor :last_before_login_on
  # Prevents unauthorized assignments
  attr_protected :login, :admin, :password, :password_confirmation, :hashed_password
	
  validates_presence_of :login, :firstname, :lastname, :mail, :if => Proc.new { |user| !user.is_a?(AnonymousUser) }
  validates_uniqueness_of :login, :if => Proc.new { |user| !user.login.blank? }
  validates_uniqueness_of :mail, :if => Proc.new { |user| !user.mail.blank? }, :case_sensitive => false
  # Login must contain lettres, numbers, underscores only
  validates_format_of :login, :with => /^[a-z0-9_\-@\.]*$/i
  validates_length_of :login, :maximum => 30
  validates_format_of :firstname, :lastname, :with => /^[\w\s\'\-\.]*$/i
  validates_length_of :firstname, :lastname, :maximum => 30
  validates_format_of :mail, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :allow_nil => true
  validates_length_of :mail, :maximum => 60, :allow_nil => true
  validates_confirmation_of :password, :allow_nil => true

  def before_create
    self.mail_notification = false
    true
  end
  
  def before_save
    # update hashed_password if password was set
    self.hashed_password = User.hash_password(self.password) if self.password
  end
  
  def reload(*args)
    @name = nil
    super
  end
  
  def identity_url=(url)
    if url.blank?
      write_attribute(:identity_url, '')
    else
      begin
        write_attribute(:identity_url, OpenIdAuthentication.normalize_identifier(url))
      rescue OpenIdAuthentication::InvalidOpenId
        # Invlaid url, don't save
      end
    end
    self.read_attribute(:identity_url)
  end
  
  # Returns the user that matches provided login and password, or nil
  def self.try_to_login(login, password)
    # Make sure no one can sign in with an empty password
    return nil if password.to_s.empty?
    user = find(:first, :conditions => ["login=?", login])
    if user
      # user is already in local database
      return nil if !user.active?
      if user.auth_source
        # user has an external authentication method
        return nil unless user.auth_source.authenticate(login, password)
      else
        # authentication with local password
        return nil unless User.hash_password(password) == user.hashed_password        
      end
    else
      # user is not yet registered, try to authenticate with available sources
      attrs = AuthSource.authenticate(login, password)
      if attrs
        user = new(*attrs)
        user.login = login
        user.language = Setting.default_language
        if user.save
          user.reload
          logger.info("User '#{user.login}' created from the LDAP") if logger
        end
      end
    end    
    user.update_attribute(:last_login_on, Time.now) if user && !user.new_record?
    user
  rescue => text
    raise text
  end
  
  # Returns the user who matches the given autologin +key+ or nil
  def self.try_to_autologin(key)
    token = Token.find_by_action_and_value('autologin', key)
    if token && (token.created_on > Setting.autologin.to_i.day.ago) && token.user && token.user.active?
      token.user.update_attribute(:last_login_on, Time.now)
      token.user
    end
  end
	
  # Return user's full name for display
  def name(formatter = nil)
    if formatter
      eval('"' + (USER_FORMATS[formatter] || USER_FORMATS[:firstname_lastname]) + '"')
    else
      @name ||= eval('"' + (USER_FORMATS[Setting.user_format] || USER_FORMATS[:firstname_lastname]) + '"')
    end
  end
  
  def active?
    self.status == STATUS_ACTIVE
  end

  def registered?
    self.status == STATUS_REGISTERED
  end
    
  def locked?
    self.status == STATUS_LOCKED
  end

  def check_password?(clear_password)
    User.hash_password(clear_password) == self.hashed_password
  end

  # Generate and set a random password.  Useful for automated user creation
  # Based on Token#generate_token_value
  #
  def random_password
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    password = ''
    40.times { |i| password << chars[rand(chars.size-1)] }
    self.password = password
    self.password_confirmation = password
    self
  end
  
  def pref
    self.preference ||= UserPreference.new(:user => self)
  end
  
  def time_zone
    @time_zone ||= (self.pref.time_zone.blank? ? nil : ActiveSupport::TimeZone[self.pref.time_zone])
  end
  
  def wants_comments_in_reverse_order?
    self.pref[:comments_sorting] == 'desc'
  end
  
  # Return user's RSS key (a 40 chars long string), used to access feeds
  def rss_key
    token = self.rss_token || Token.create(:user => self, :action => 'feeds')
    token.value
  end
  
  # Return an array of project ids for which the user has explicitly turned mail notifications on
  def notified_projects_ids
    @notified_projects_ids ||= memberships.select {|m| m.mail_notification?}.collect(&:project_id)
  end
  
  def notified_project_ids=(ids)
    Member.update_all("mail_notification = #{connection.quoted_false}", ['user_id = ?', id])
    Member.update_all("mail_notification = #{connection.quoted_true}", ['user_id = ? AND project_id IN (?)', id, ids]) if ids && !ids.empty?
    @notified_projects_ids = nil
    notified_projects_ids
  end
  
  def self.find_by_rss_key(key)
    token = Token.find_by_value(key)
    token && token.user.active? ? token.user : nil
  end
  
  # Makes find_by_mail case-insensitive
  def self.find_by_mail(mail)
    find(:first, :conditions => ["LOWER(mail) = ?", mail.to_s.downcase])
  end

  # Sort users by their display names
  def <=>(user)
    self.to_s.downcase <=> user.to_s.downcase
  end
  
  def to_s
    name
  end
  
  def logged?
    true
  end
  
  def anonymous?
    !logged?
  end
  
  # Return user's roles for project
  def roles_for_project(project)
    roles = []
    # No role on archived projects
    return roles unless project && project.active?
    if logged?
      # Find project membership
      membership = memberships.detect {|m| m.project_id == project.id}
      if membership
        roles = membership.roles
      else
        @role_non_member ||= Role.non_member
        roles << @role_non_member
      end
    else
      @role_anonymous ||= Role.anonymous
      roles << @role_anonymous
    end
    roles
  end
  
  # Return true if the user is a member of project
  def member_of?(project)
    !roles_for_project(project).detect {|role| role.member?}.nil?
  end
  
  # Return true if the user is allowed to do the specified action on project
  # action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  def allowed_to?(action, project, options={})
    if project
      # No action allowed on archived projects
      return false unless project.active?
      # No action allowed on disabled modules
      return false unless project.allows_to?(action)
      # Admin users are authorized for anything else
      return true if admin?
      
      roles = roles_for_project(project)
      return false unless roles
      roles.detect {|role| (project.is_public? || role.member?) && role.allowed_to?(action)}
      
    elsif options[:global]
      # authorize if user has at least one role that has this permission
      roles = memberships.collect {|m| m.roles}.flatten.uniq
      roles.detect {|r| r.allowed_to?(action)} || (self.logged? ? Role.non_member.allowed_to?(action) : Role.anonymous.allowed_to?(action))
    else
      false
    end
  end
  
  def self.current=(user)
    @current_user = user
  end
  
  def self.current
    @current_user ||= User.anonymous
  end
  
  # Returns the anonymous user.  If the anonymous user does not exist, it is created.  There can be only
  # one anonymous user per database.
  def self.anonymous
    anonymous_user = AnonymousUser.find(:first)
    if anonymous_user.nil?
      anonymous_user = AnonymousUser.create(:lastname => 'Anonymous', :firstname => '', :mail => '', :login => '', :status => 0)
      raise 'Unable to create the anonymous user.' if anonymous_user.new_record?
    end
    anonymous_user
  end
  
  protected
  
  def validate
    # Password length validation based on setting
    if !password.nil? && password.size < Setting.password_min_length.to_i
      errors.add(:password, :too_short, :count => Setting.password_min_length.to_i)
    end
  end
  
  private
  
  # Return password digest
  def self.hash_password(clear_password)
    Digest::SHA1.hexdigest(clear_password || "")
  end
end

class AnonymousUser < User
  
  def validate_on_create
    # There should be only one AnonymousUser in the database
    errors.add_to_base 'An anonymous user already exists.' if AnonymousUser.find(:first)
  end
  
  def available_custom_fields
    []
  end
  
  # Overrides a few properties
  def logged?; false end
  def admin; false end
  def name; 'Anonymous' end
  def mail; nil end
  def time_zone; nil end
  def rss_key; nil end
end
