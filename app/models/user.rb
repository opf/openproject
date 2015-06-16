#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'digest/sha1'

class User < Principal
  include ActiveModel::ForbiddenAttributesProtection
  include User::Authorization

  # Account statuses
  # Code accessing the keys assumes they are ordered, which they are since Ruby 1.9
  STATUSES = {
    builtin: 0,
    active: 1,
    registered: 2,
    locked: 3
  }

  USER_FORMATS_STRUCTURE = {
    firstname_lastname: [:firstname, :lastname],
    firstname: [:firstname],
    lastname_firstname: [:lastname, :firstname],
    lastname_coma_firstname: [:lastname, :firstname],
    username: [:login]
  }

  def self.user_format_structure_to_format(key, delimiter = ' ')
    USER_FORMATS_STRUCTURE[key].map { |elem| "\#{#{elem}}" }.join(delimiter)
  end

  USER_FORMATS = {
    firstname_lastname:      User.user_format_structure_to_format(:firstname_lastname, ' '),
    firstname:               User.user_format_structure_to_format(:firstname),
    lastname_firstname:      User.user_format_structure_to_format(:lastname_firstname, ' '),
    lastname_coma_firstname: User.user_format_structure_to_format(:lastname_coma_firstname, ', '),
    username:                User.user_format_structure_to_format(:username)
  }

  USER_MAIL_OPTION_ALL            = ['all', :label_user_mail_option_all]
  USER_MAIL_OPTION_SELECTED       = ['selected', :label_user_mail_option_selected]
  USER_MAIL_OPTION_ONLY_MY_EVENTS = ['only_my_events', :label_user_mail_option_only_my_events]
  USER_MAIL_OPTION_ONLY_ASSIGNED  = ['only_assigned', :label_user_mail_option_only_assigned]
  USER_MAIL_OPTION_ONLY_OWNER     = ['only_owner', :label_user_mail_option_only_owner]
  USER_MAIL_OPTION_NON            = ['none', :label_user_mail_option_none]

  MAIL_NOTIFICATION_OPTIONS = [
    USER_MAIL_OPTION_ALL,
    USER_MAIL_OPTION_SELECTED,
    USER_MAIL_OPTION_ONLY_MY_EVENTS,
    USER_MAIL_OPTION_ONLY_ASSIGNED,
    USER_MAIL_OPTION_ONLY_OWNER,
    USER_MAIL_OPTION_NON
  ]

  has_many :group_users
  has_many :groups, through: :group_users,
                    after_add: Proc.new { |user, group| group.user_added(user) },
                    after_remove: Proc.new { |user, group| group.user_removed(user) }
  has_many :categories, foreign_key: 'assigned_to_id',
                        dependent: :nullify
  has_many :assigned_issues, foreign_key: 'assigned_to_id',
                             class_name: 'WorkPackage',
                             dependent: :nullify
  has_many :responsible_for_issues, foreign_key: 'responsible_id',
                                    class_name: 'WorkPackage',
                                    dependent: :nullify
  has_many :responsible_for_projects, foreign_key: 'responsible_id',
                                      class_name: 'Project',
                                      dependent: :nullify
  has_many :watches, class_name: 'Watcher',
                     dependent: :delete_all
  has_many :changesets, dependent: :nullify
  has_many :passwords, class_name: 'UserPassword',
                       order: 'id DESC',
                       readonly: true,
                       dependent: :destroy,
                       inverse_of: :user
  has_one :preference, dependent: :destroy, class_name: 'UserPreference'
  has_one :rss_token, dependent: :destroy, class_name: 'Token', conditions: "action='feeds'"
  has_one :api_token, dependent: :destroy, class_name: 'Token', conditions: "action='api'"
  belongs_to :auth_source

  # TODO: this is from Principal. the inheritance doesn't work correctly
  # note: it doesn't fail in development mode
  # see: https://github.com/rails/rails/issues/3847
  has_many :members, foreign_key: 'user_id', dependent: :destroy
  has_many :memberships, class_name: 'Member', foreign_key: 'user_id', include: [:project, :roles], conditions: "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}", order: "#{Project.table_name}.name"
  has_many :projects, through: :memberships

  # Active non-anonymous users scope
  scope :not_builtin,
        conditions: "#{User.table_name}.status <> #{STATUSES[:builtin]}"

  # Users blocked via brute force prevention
  # use lambda here, so time is evaluated on each query
  scope :blocked, lambda { create_blocked_scope(true) }
  scope :not_blocked, lambda { create_blocked_scope(false) }

  def self.create_blocked_scope(blocked)
    block_duration = Setting.brute_force_block_minutes.to_i.minutes
    blocked_if_login_since = Time.now - block_duration
    negation = blocked ? '' : 'NOT'
    where("#{negation} (failed_login_count >= ? AND last_failed_login_on > ?)",
          Setting.brute_force_block_after_failed_logins.to_i,
          blocked_if_login_since)
  end

  acts_as_customizable

  attr_accessor :password, :password_confirmation
  attr_accessor :last_before_login_on

  validates_presence_of :login,
                        :firstname,
                        :lastname,
                        :mail,
                        unless: Proc.new { |user| user.is_a?(AnonymousUser) || user.is_a?(DeletedUser) || user.is_a?(SystemUser) }

  validates_uniqueness_of :login, if: Proc.new { |user| !user.login.blank? }, case_sensitive: false
  validates_uniqueness_of :mail, allow_blank: true, case_sensitive: false
  # Login must contain letters, numbers, underscores only
  validates_format_of :login, with: /\A[a-z0-9_\-@\.+ ]*\z/i
  validates_length_of :login, maximum: 256
  validates_length_of :firstname, :lastname, maximum: 30
  validates_format_of :mail, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: true
  validates_length_of :mail, maximum: 60, allow_nil: true
  validates_confirmation_of :password, allow_nil: true
  validates_inclusion_of :mail_notification, in: MAIL_NOTIFICATION_OPTIONS.map(&:first), allow_blank: true

  validate :password_meets_requirements

  after_save :update_password
  before_create :sanitize_mail_notification_setting
  before_destroy :delete_associated_private_queries
  before_destroy :reassign_associated
  before_destroy :remove_from_filter

  scope :in_group, lambda {|group|
    group_id = group.is_a?(Group) ? group.id : group.to_i
    { conditions: ["#{User.table_name}.id IN (SELECT gu.user_id FROM #{table_name_prefix}group_users#{table_name_suffix} gu WHERE gu.group_id = ?)", group_id] }
  }
  scope :not_in_group, lambda {|group|
    group_id = group.is_a?(Group) ? group.id : group.to_i
    { conditions: ["#{User.table_name}.id NOT IN (SELECT gu.user_id FROM #{table_name_prefix}group_users#{table_name_suffix} gu WHERE gu.group_id = ?)", group_id] }
  }
  scope :admin, conditions: { admin: true }

  def sanitize_mail_notification_setting
    self.mail_notification = Setting.default_notification_option if mail_notification.blank?
    true
  end

  def current_password
    passwords.first
  end

  def password_expired?
    current_password.expired?
  end

  # create new password if password was set
  def update_password
    if password && auth_source_id.blank?
      new_password = passwords.build
      new_password.plain_password = password
      new_password.save

      # force reload of passwords, so the new password is sorted to the top
      passwords(true)

      clean_up_former_passwords
    end
  end

  def reload(*args)
    @name = nil
    @projects_by_role = nil
    super
  end

  def mail=(arg)
    write_attribute(:mail, arg.to_s.strip)
  end

  def self.search_in_project(query, options)
    Project.find(options.fetch(:project)).users.like(query)
  end

  def self.register_allowance_evaluator(filter)
    self.registered_allowance_evaluators ||= []

    registered_allowance_evaluators << filter
  end

  # replace by class_attribute when on rails 3.x
  class_eval do
    def self.registered_allowance_evaluators() nil end
    def self.registered_allowance_evaluators=(val)
      singleton_class.class_eval do
        define_method(:registered_allowance_evaluators) do
          val
        end
      end
    end
  end

  register_allowance_evaluator OpenProject::PrincipalAllowanceEvaluator::Default

  # Returns the user that matches provided login and password, or nil
  def self.try_to_login(login, password)
    # Make sure no one can sign in with an empty password
    return nil if password.to_s.empty?
    user = find_by_login(login)
    user = if user
             try_authentication_for_existing_user(user, password)
           else
             try_authentication_and_create_user(login, password)
    end
    unless prevent_brute_force_attack(user, login).nil?
      user.log_successful_login if user && !user.new_record?
      return user
    end
    nil
  end

  # Tries to authenticate a user in the database via external auth source
  # or password stored in the database
  def self.try_authentication_for_existing_user(user, password)
    return nil if !user.active? || OpenProject::Configuration.disable_password_login?
    if user.auth_source
      # user has an external authentication method
      return nil unless user.auth_source.authenticate(user.login, password)
    else
      # authentication with local password
      return nil unless user.check_password?(password)
      return nil if user.force_password_change
      return nil if user.password_expired?
    end
    user
  end

  # Tries to authenticate with available sources and creates user on success
  def self.try_authentication_and_create_user(login, password)
    return nil if OpenProject::Configuration.disable_password_login?

    user = nil
    attrs = AuthSource.authenticate(login, password)
    if attrs
      # login is both safe and protected in chilis core code
      # in case it's intentional we keep it that way
      user = new(attrs.except(:login))
      user.login = login
      user.language = Setting.default_language
      if user.save
        user.reload
        logger.info("User '#{user.login}' created from external auth source: #{user.auth_source.type} - #{user.auth_source.name}") if logger && user.auth_source
      end
    end
    user
  end

  # Returns the user who matches the given autologin +key+ or nil
  def self.try_to_autologin(key)
    tokens = Token.find_all_by_action_and_value('autologin', key)
    # Make sure there's only 1 token that matches the key
    if tokens.size == 1
      token = tokens.first
      if (token.created_on > Setting.autologin.to_i.day.ago) && token.user && token.user.active?
        token.user.log_successful_login
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

  # Return user's authentication provider for display
  def authentication_provider
    return if identity_url.blank?
    identity_url.split(':', 2).first.titleize
  end

  def status_name
    STATUSES.keys[status].to_s
  end

  def active?
    status == STATUSES[:active]
  end

  def registered?
    status == STATUSES[:registered]
  end

  def locked?
    status == STATUSES[:locked]
  end

  ##
  # Allows the API and other sources to determine locking actions
  # on represented collections of children of Principals.
  # This only covers the transition from:
  # lockable?: active -> locked.
  # activatable?: locked -> active.
  alias_method :lockable?, :active?
  alias_method :activatable?, :locked?

  def activate
    self.status = STATUSES[:active]
  end

  def register
    self.status = STATUSES[:registered]
  end

  def lock
    self.status = STATUSES[:locked]
  end

  def activate!
    update_attribute(:status, STATUSES[:active])
  end

  def register!
    update_attribute(:status, STATUSES[:registered])
  end

  def lock!
    update_attribute(:status, STATUSES[:locked])
  end

  # Returns true if +clear_password+ is the correct user's password, otherwise false
  def check_password?(clear_password)
    if auth_source_id.present?
      auth_source.authenticate(login, clear_password)
    else
      return false if current_password.nil?
      current_password.same_as_plain_password?(clear_password)
    end
  end

  # Does the backend storage allow this user to change their password?
  def change_password_allowed?
    return false if uses_external_authentication? ||
                    OpenProject::Configuration.disable_password_login?
    return true if auth_source_id.blank?
    auth_source.allow_password_changes?
  end

  # Is the user authenticated via an external authentication source via OmniAuth?
  def uses_external_authentication?
    identity_url.present?
  end

  #
  # Generate and set a random password.
  #
  # Also force a password change on the next login, since random passwords
  # are at some point given to the user, we do this via email. These passwords
  # are stored unencrypted in mail accounts, so they must only be valid for
  # a short time.
  def random_password!
    self.password = OpenProject::Passwords::Generator.random_password
    self.password_confirmation = password
    self.force_password_change = true
    self
  end

  ##
  # Brute force prevention - public instance methods
  #
  def failed_too_many_recent_login_attempts?
    block_threshold = Setting.brute_force_block_after_failed_logins.to_i
    return false if block_threshold == 0  # disabled
    (last_failed_login_within_block_time? and
            failed_login_count >= block_threshold)
  end

  def log_failed_login
    log_failed_login_count
    log_failed_login_timestamp
    save
  end

  def log_successful_login
    update_attribute(:last_login_on, Time.now)
  end

  def pref
    preference || build_preference
  end

  def time_zone
    @time_zone ||= (pref.time_zone.blank? ? nil : ActiveSupport::TimeZone[pref.time_zone])
  end

  def impaired=(value)
    pref.update_attribute(:impaired, !!value)
    !!value
  end

  def impaired
    (anonymous? && Setting.accessibility_mode_for_anonymous?) || !!pref.impaired
  end

  def impaired?
    impaired
  end

  def wants_comments_in_reverse_order?
    pref[:comments_sorting] == 'desc'
  end

  # Return user's RSS key (a 40 chars long string), used to access feeds
  def rss_key
    token = rss_token || Token.create(user: self, action: 'feeds')
    token.value
  end

  # Return user's API key (a 40 chars long string), used to access the API
  def api_key
    token = api_token || create_api_token(action: 'api')
    token.value
  end

  # Return an array of project ids for which the user has explicitly turned mail notifications on
  def notified_projects_ids
    @notified_projects_ids ||= memberships.select(&:mail_notification?).map(&:project_id)
  end

  def notified_project_ids=(ids)
    Member.update_all("mail_notification = #{connection.quoted_false}", ['user_id = ?', id])
    Member.update_all("mail_notification = #{connection.quoted_true}", ['user_id = ? AND project_id IN (?)', id, ids]) if ids && !ids.empty?
    @notified_projects_ids = nil
    notified_projects_ids
  end

  def valid_notification_options
    self.class.valid_notification_options(self)
  end

  # Only users that belong to more than 1 project can select projects for which they are notified
  def self.valid_notification_options(user = nil)
    # Note that @user.membership.size would fail since AR ignores
    # :include association option when doing a count
    if user.nil? || user.memberships.length < 1
      MAIL_NOTIFICATION_OPTIONS.reject { |option| option.first == 'selected' }
    else
      MAIL_NOTIFICATION_OPTIONS
    end
  end

  # Find a user account by matching the exact login and then a case-insensitive
  # version.  Exact matches will be given priority.
  def self.find_by_login(login)
    # force string comparison to be case sensitive on MySQL
    type_cast = (OpenProject::Database.mysql?) ? 'BINARY' : ''
    # First look for an exact match
    user = first(conditions: ["#{type_cast} login = ?", login])
    # Fail over to case-insensitive if none was found
    user ||= first(conditions: ["#{type_cast} LOWER(login) = ?", login.to_s.downcase])
  end

  def self.find_by_rss_key(key)
    token = Token.find_by_value(key)
    token && token.user.active? && Setting.feeds_enabled? ? token.user : nil
  end

  def self.find_by_api_key(key)
    token = Token.find_by_action_and_value('api', key)
    token && token.user.active? ? token.user : nil
  end

  # Makes find_by_mail case-insensitive
  def self.find_by_mail(mail)
    find(:first, conditions: ['LOWER(mail) = ?', mail.to_s.downcase])
  end

  def self.find_all_by_mails(mails)
    find(:all, conditions: ['LOWER(mail) IN (?)', mails])
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
      membership = memberships.detect { |m| m.project_id == project.id }
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

  # Cheap version of Project.visible.count
  def number_of_known_projects
    if admin?
      Project.count
    else
      Project.public.count + memberships.size
    end
  end

  # Return true if the user is a member of project
  def member_of?(project)
    roles_for_project(project).any?(&:member?)
  end

  # Returns a hash of user's projects grouped by roles
  def projects_by_role
    return @projects_by_role if @projects_by_role

    @projects_by_role = Hash.new { |h, k| h[k] = [] }
    memberships.each do |membership|
      membership.roles.each do |role|
        @projects_by_role[role] << membership.project if membership.project
      end
    end
    @projects_by_role.each do |_role, projects|
      projects.uniq!
    end

    @projects_by_role
  end

  # Returns true if user is arg or belongs to arg
  def is_or_belongs_to?(arg)
    if arg.is_a?(User)
      self == arg
    elsif arg.is_a?(Group)
      arg.users.include?(self)
    else
      false
    end
  end

  # Return true if the user is allowed to do the specified action on a specific context
  # Action can be:
  # * a parameter-like Hash (eg. :controller => '/projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  # Context can be:
  # * a project : returns true if user is allowed to do the specified action on this project
  # * a group of projects : returns true if user is allowed on every project
  # * nil with options[:global] set : check if user has at least one role allowed for this action,
  #   or falls back to Non Member / Anonymous permissions depending if the user is logged
  def allowed_to?(action, context, options = {})
    if action.is_a?(Hash) && action[:controller] && action[:controller].to_s.starts_with?('/')
      action = action.dup
      action[:controller] = action[:controller][1..-1]
    end

    if context.is_a?(Project)
      allowed_to_in_project?(action, context, options)
    elsif context.is_a?(Array)
      # Authorize if user is authorized on every element of the array
      context.present? && context.all? do |project|
        allowed_to?(action, project, options)
      end
    elsif options[:global]
      allowed_to_globally?(action, options)
    else
      false
    end
  end

  def allowed_to_in_project?(action, project, options = {})
    initialize_allowance_evaluators

    # No action allowed on archived projects
    return false unless project.active?
    # No action allowed on disabled modules
    return false unless project.allows_to?(action)
    # Admin users are authorized for anything else
    return true if admin?

    candidates_for_project_allowance(project).any? do |candidate|
      denied = @registered_allowance_evaluators.any? do |filter|
        filter.denied_for_project? candidate, action, project, options
      end

      !denied && @registered_allowance_evaluators.any? do |filter|
        filter.granted_for_project? candidate, action, project, options
      end
    end
  end

  # Is the user allowed to do the specified action on any project?
  # See allowed_to? for the actions and valid options.
  def allowed_to_globally?(action, options = {})
    # Admin users are always authorized
    return true if admin?

    initialize_allowance_evaluators
    # authorize if user has at least one membership granting this permission
    candidates_for_global_allowance.any? do |candidate|
      denied = @registered_allowance_evaluators.any? do |evaluator|
        evaluator.denied_for_global? candidate, action, options
      end

      !denied && @registered_allowance_evaluators.any? do |evaluator|
        evaluator.granted_for_global? candidate, action, options
      end
    end
  end

  # Utility method to help check if a user should be notified about an
  # event.
  def notify_about?(object)
    case mail_notification
    when 'all'
      true
    when 'selected'
      # user receives notifications for created/assigned issues on unselected projects
      if object.is_a?(WorkPackage) && (object.author == self || is_or_belongs_to?(object.assigned_to))
        true
      else
        false
      end
    when 'none'
      false
    when 'only_my_events'
      if object.is_a?(WorkPackage) && (object.author == self || is_or_belongs_to?(object.assigned_to))
        true
      else
        false
      end
    when 'only_assigned'
      if object.is_a?(WorkPackage) && is_or_belongs_to?(object.assigned_to)
        true
      else
        false
      end
    when 'only_owner'
      if object.is_a?(WorkPackage) && object.author == self
        true
      else
        false
      end
    else
      false
    end
  end

  def reported_work_package_count
    WorkPackage.on_active_project.with_author(self).visible.count
  end

  def self.current=(user)
    @current_user = user
  end

  def self.current
    @current_user ||= User.anonymous
  end

  def roles(project)
    User.current.admin? ? Role.all : User.current.roles_for_project(project)
  end

  # Returns the anonymous user.  If the anonymous user does not exist, it is created.  There can be only
  # one anonymous user per database.
  def self.anonymous
    anonymous_user = AnonymousUser.find(:first)
    if anonymous_user.nil?
      (anonymous_user = AnonymousUser.new.tap do |u|
        u.lastname = 'Anonymous'
        u.login = ''
        u.firstname = ''
        u.mail = ''
        u.status = 0
      end).save
      raise 'Unable to create the anonymous user.' if anonymous_user.new_record?
    end
    anonymous_user
  end

  def self.system
    system_user = SystemUser.first
    if system_user.nil?
      (system_user = SystemUser.new.tap do |u|
        u.lastname = 'System'
        u.login = ''
        u.firstname = ''
        u.mail = ''
        u.admin = false
        u.status = User::STATUSES[:locked]
        u.first_login = false
        u.random_password!
      end).save
      raise 'Unable to create the automatic migration user.' if system_user.new_record?
    end
    system_user
  end

  def latest_news(options = {})
    News.latest_for self, options
  end

  def latest_projects(options = {})
    Project.latest_for self, options
  end

  protected

  # Password requirement validation based on settings
  def password_meets_requirements
    # Passwords are stored hashed as UserPasswords,
    # self.password is only set when it was changed after the last
    # save. Otherwise, password is nil.
    unless password.nil? or anonymous?
      password_errors = OpenProject::Passwords::Evaluator.errors_for_password(password)
      password_errors.each { |error| errors.add(:password, error) }

      if former_passwords_include?(password)
        errors.add(:password,
                   I18n.t(:reused,
                          count: Setting[:password_count_former_banned].to_i,
                          scope: [:activerecord,
                                  :errors,
                                  :models,
                                  :user,
                                  :attributes,
                                  :password]))
      end
    end
  end

  private

  def initialize_allowance_evaluators
    @registered_allowance_evaluators ||= self.class.registered_allowance_evaluators.map do |evaluator|
      evaluator.new(self)
    end
  end

  def candidates_for_global_allowance
    @registered_allowance_evaluators.map(&:global_granting_candidates).flatten.uniq
  end

  def candidates_for_project_allowance(project)
    @registered_allowance_evaluators.map { |f| f.project_granting_candidates(project) }.flatten.uniq
  end

  def former_passwords_include?(password)
    return false if Setting[:password_count_former_banned].to_i == 0
    ban_count = Setting[:password_count_former_banned].to_i
    # make reducing the number of banned former passwords immediately effective
    # by only checking this number of former passwords
    passwords[0, ban_count].any? { |f| f.same_as_plain_password?(password) }
  end

  def clean_up_former_passwords
    # minimum 1 to keep the actual user password
    keep_count = [1, Setting[:password_count_former_banned].to_i].max
    (passwords[keep_count..-1] || []).each(&:destroy)
  end

  def remove_from_filter
    timelines_filter = ['planning_element_responsibles', 'planning_element_assignee', 'project_responsibles']
    substitute = DeletedUser.first

    timelines = Timeline.all(conditions: ['options LIKE ?', "%#{id}%"])

    timelines.each do |timeline|
      timelines_filter.each do |field|
        fieldOptions = timeline.options[field]
        if fieldOptions && index = fieldOptions.index(id.to_s)
          timeline.options_will_change!
          fieldOptions[index] = substitute.id.to_s
        end
      end

      timeline.save!
    end
  end

  def reassign_associated
    substitute = DeletedUser.first

    [WorkPackage, Attachment, WikiContent, News, Comment, Message].each do |klass|
      klass.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
    end

    [TimeEntry, Journal, ::Query].each do |klass|
      klass.update_all ['user_id = ?', substitute.id], ['user_id = ?', id]
    end

    JournalManager.update_user_references id, substitute.id
  end

  def delete_associated_private_queries
    ::Query.delete_all ['user_id = ? AND is_public = ?', id, false]
  end

  ##
  # Brute force prevention - class methods
  #
  def self.prevent_brute_force_attack(user, login)
    if user.nil?
      register_failed_login_attempt_if_user_exists_for(login)
    else
      block_user_if_too_many_recent_attempts_failed(user)
    end
  end

  def self.register_failed_login_attempt_if_user_exists_for(login)
    user = User.find_by_login(login)
    user.log_failed_login if user.present?
    nil
  end

  def self.reset_failed_login_count_for(user)
    user.update_attribute(:failed_login_count, 0) unless user.new_record?
  end

  def self.block_user_if_too_many_recent_attempts_failed(user)
    if user.failed_too_many_recent_login_attempts?
      user = nil
    else
      reset_failed_login_count_for user
    end

    user
  end

  ##
  # Brute force prevention - instance methods
  #
  def last_failed_login_within_block_time?
    block_duration = Setting.brute_force_block_minutes.to_i.minutes
    last_failed_login_on and
      Time.now - last_failed_login_on < block_duration
  end

  def log_failed_login_count
    if last_failed_login_within_block_time?
      self.failed_login_count += 1
    else
      self.failed_login_count = 1
    end
  end

  def log_failed_login_timestamp
    self.last_failed_login_on = Time.now
  end

  def self.default_admin_account_changed?
    !User.active.find_by_login('admin').try(:current_password).try(:same_as_plain_password?, 'admin')
  end
end

class AnonymousUser < User
  validate :validate_unique_anonymous_user, on: :create

  # There should be only one AnonymousUser in the database
  def validate_unique_anonymous_user
    errors.add :base, 'An anonymous user already exists.' if AnonymousUser.find(:first)
  end

  def available_custom_fields
    []
  end

  # Overrides a few properties
  def logged?; false end

  def admin; false end

  def name(*_args); I18n.t(:label_user_anonymous) end

  def mail; nil end

  def time_zone; nil end

  def rss_key; nil end

  def destroy; false end
end

class DeletedUser < User
  validate :validate_unique_deleted_user, on: :create

  # There should be only one DeletedUser in the database
  def validate_unique_deleted_user
    errors.add :base, 'A DeletedUser already exists.' if DeletedUser.find(:first)
  end

  def self.first
    find_or_create_by_type_and_status(to_s, STATUSES[:builtin])
  end

  # Overrides a few properties
  def logged?; false end

  def admin; false end

  def name(*_args); I18n.t('user.deleted') end

  def mail; nil end

  def time_zone; nil end

  def rss_key; nil end

  def destroy; false end
end
