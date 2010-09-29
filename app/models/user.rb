# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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

class User < Principal

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

  MAIL_NOTIFICATION_OPTIONS = [
                               [:all, :label_user_mail_option_all],
                               [:selected, :label_user_mail_option_selected],
                               [:none, :label_user_mail_option_none],
                               [:only_my_events, :label_user_mail_option_only_my_events],
                               [:only_assigned, :label_user_mail_option_only_assigned],
                               [:only_owner, :label_user_mail_option_only_owner]
                              ]

  has_and_belongs_to_many :groups, :after_add => Proc.new {|user, group| group.user_added(user)},
                                   :after_remove => Proc.new {|user, group| group.user_removed(user)}
  has_many :issue_categories, :foreign_key => 'assigned_to_id', :dependent => :nullify
  has_many :changesets, :dependent => :nullify
  has_one :preference, :dependent => :destroy, :class_name => 'UserPreference'
  has_one :rss_token, :dependent => :destroy, :class_name => 'Token', :conditions => "action='feeds'"
  has_one :api_token, :dependent => :destroy, :class_name => 'Token', :conditions => "action='api'"
  belongs_to :auth_source
  
  # Active non-anonymous users scope
  named_scope :active, :conditions => "#{User.table_name}.status = #{STATUS_ACTIVE}"
  
  acts_as_customizable
  
  attr_accessor :password, :password_confirmation
  attr_accessor :last_before_login_on
  # Prevents unauthorized assignments
  attr_protected :login, :admin, :password, :password_confirmation, :hashed_password, :group_ids
	
  validates_presence_of :login, :firstname, :lastname, :mail, :if => Proc.new { |user| !user.is_a?(AnonymousUser) }
  validates_uniqueness_of :login, :if => Proc.new { |user| !user.login.blank? }, :case_sensitive => false
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
    self.mail_notification = Setting.default_notification_option if self.mail_notification.blank?
    true
  end
  
  def before_save
    # update hashed_password if password was set
    self.hashed_password = User.hash_password(self.password) if self.password && self.auth_source_id.blank?
  end
  
  def reload(*args)
    @name = nil
    super
  end
  
  def mail=(arg)
    write_attribute(:mail, arg.to_s.strip)
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
    user = find_by_login(login)
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
        user = new(attrs)
        user.login = login
        user.language = Setting.default_language
        if user.save
          user.reload
          logger.info("User '#{user.login}' created from external auth source: #{user.auth_source.type} - #{user.auth_source.name}") if logger && user.auth_source
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
    tokens = Token.find_all_by_action_and_value('autologin', key)
    # Make sure there's only 1 token that matches the key
    if tokens.size == 1
      token = tokens.first
      if (token.created_on > Setting.autologin.to_i.day.ago) && token.user && token.user.active?
        token.user.update_attribute(:last_login_on, Time.now)
        token.user
      end
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

  def activate
    self.status = STATUS_ACTIVE
  end

  def register
    self.status = STATUS_REGISTERED
  end

  def lock
    self.status = STATUS_LOCKED
  end

  def activate!
    update_attribute(:status, STATUS_ACTIVE)
  end

  def register!
    update_attribute(:status, STATUS_REGISTERED)
  end

  def lock!
    update_attribute(:status, STATUS_LOCKED)
  end

  def check_password?(clear_password)
    if auth_source_id.present?
      auth_source.authenticate(self.login, clear_password)
    else
      User.hash_password(clear_password) == self.hashed_password
    end
  end

  # Does the backend storage allow this user to change their password?
  def change_password_allowed?
    return true if auth_source_id.blank?
    return auth_source.allow_password_changes?
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

  # Return user's API key (a 40 chars long string), used to access the API
  def api_key
    token = self.api_token || self.create_api_token(:action => 'api')
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

  # Only users that belong to more than 1 project can select projects for which they are notified
  def valid_notification_options
    # Note that @user.membership.size would fail since AR ignores
    # :include association option when doing a count
    if memberships.length < 1
      MAIL_NOTIFICATION_OPTIONS.delete_if {|option| option.first == :selected}
    else
      MAIL_NOTIFICATION_OPTIONS
    end
  end

  # Find a user account by matching the exact login and then a case-insensitive
  # version.  Exact matches will be given priority.
  def self.find_by_login(login)
    # force string comparison to be case sensitive on MySQL
    type_cast = (ActiveRecord::Base.connection.adapter_name == 'MySQL') ? 'BINARY' : ''
    
    # First look for an exact match
    user = first(:conditions => ["#{type_cast} login = ?", login])
    # Fail over to case-insensitive if none was found
    user ||= first(:conditions => ["#{type_cast} LOWER(login) = ?", login.to_s.downcase])
  end

  def self.find_by_rss_key(key)
    token = Token.find_by_value(key)
    token && token.user.active? ? token.user : nil
  end
  
  def self.find_by_api_key(key)
    token = Token.find_by_action_and_value('api', key)
    token && token.user.active? ? token.user : nil
  end
  
  # Makes find_by_mail case-insensitive
  def self.find_by_mail(mail)
    find(:first, :conditions => ["LOWER(mail) = ?", mail.to_s.downcase])
  end
  
  def to_s
    name
  end
  
  # Returns the current day according to user's time zone
  def today
    if time_zone.nil?
      Date.today
    else
      Time.now.in_time_zone(time_zone).to_date
    end
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
  
  # Return true if the user is allowed to do the specified action on a specific context
  # Action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  # Context can be:
  # * a project : returns true if user is allowed to do the specified action on this project
  # * a group of projects : returns true if user is allowed on every project
  # * nil with options[:global] set : check if user has at least one role allowed for this action, 
  #   or falls back to Non Member / Anonymous permissions depending if the user is logged
  def allowed_to?(action, project, options={})
    if project && project.is_a?(Project)
      # No action allowed on archived projects
      return false unless project.active?
      # No action allowed on disabled modules
      return false unless project.allows_to?(action)
      # Admin users are authorized for anything else
      return true if admin?
      
      roles = roles_for_project(project)
      return false unless roles
      roles.detect {|role| (project.is_public? || role.member?) && role.allowed_to?(action)}
      
    elsif project && project.is_a?(Array)
      # Authorize if user is authorized on every element of the array
      project.inject do |memo,p|
        memo && allowed_to?(action,p,options)
      end
    elsif options[:global]
      # Admin users are always authorized
      return true if admin?
      
      # authorize if user has at least one role that has this permission
      roles = memberships.collect {|m| m.roles}.flatten.uniq
      roles.detect {|r| r.allowed_to?(action)} || (self.logged? ? Role.non_member.allowed_to?(action) : Role.anonymous.allowed_to?(action))
    else
      false
    end
  end

  # Is the user allowed to do the specified action on any project?
  # See allowed_to? for the actions and valid options.
  def allowed_to_globally?(action, options)
    allowed_to?(action, nil, options.reverse_merge(:global => true))
  end
  
  # Utility method to help check if a user should be notified about an
  # event.
  #
  # TODO: only supports Issue events currently
  def notify_about?(object)
    case mail_notification.to_sym
    when :all
      true
    when :selected
      # Handled by the Project
    when :none
      false
    when :only_my_events
      if object.is_a?(Issue) && (object.author == self || object.assigned_to == self)
        true
      else
        false
      end
    when :only_assigned
      if object.is_a?(Issue) && object.assigned_to == self
        true
      else
        false
      end
    when :only_owner
      if object.is_a?(Issue) && object.author == self
        true
      else
        false
      end
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
  def name(*args); I18n.t(:label_user_anonymous) end
  def mail; nil end
  def time_zone; nil end
  def rss_key; nil end
end
