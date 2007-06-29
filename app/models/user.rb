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
  STATUS_ACTIVE     = 1
  STATUS_REGISTERED = 2
  STATUS_LOCKED     = 3

  has_many :memberships, :class_name => 'Member', :include => [ :project, :role ], :conditions => "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}", :order => "#{Project.table_name}.name", :dependent => :delete_all
  has_many :projects, :through => :memberships
  has_many :custom_values, :dependent => :delete_all, :as => :customized
  has_many :issue_categories, :foreign_key => 'assigned_to_id', :dependent => :nullify
  has_one :preference, :dependent => :destroy, :class_name => 'UserPreference'
  has_one :rss_key, :dependent => :destroy, :class_name => 'Token', :conditions => "action='feeds'"
  belongs_to :auth_source
  
  attr_accessor :password, :password_confirmation
  attr_accessor :last_before_login_on
  # Prevents unauthorized assignments
  attr_protected :login, :admin, :password, :password_confirmation, :hashed_password
	
  validates_presence_of :login, :firstname, :lastname, :mail
  validates_uniqueness_of :login, :mail	
  # Login must contain lettres, numbers, underscores only
  validates_format_of :login, :with => /^[a-z0-9_\-@\.]+$/i
  validates_length_of :login, :maximum => 30
  validates_format_of :firstname, :lastname, :with => /^[\w\s\'\-]*$/i
  validates_length_of :firstname, :lastname, :maximum => 30
  validates_format_of :mail, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_length_of :mail, :maximum => 60
  # Password length between 4 and 12
  validates_length_of :password, :in => 4..12, :allow_nil => true
  validates_confirmation_of :password, :allow_nil => true
  validates_associated :custom_values, :on => :update

  def before_save
    # update hashed_password if password was set
    self.hashed_password = User.hash_password(self.password) if self.password
  end

  def self.active
    with_scope :find => { :conditions => [ "status = ?", STATUS_ACTIVE ] } do 
      yield 
    end 
  end
  
  def self.find_active(*args)
    active do
      find(*args)
    end
  end
  
  # Returns the user that matches provided login and password, or nil
  def self.try_to_login(login, password)
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
        onthefly = new(*attrs)
        onthefly.login = login
        onthefly.language = Setting.default_language
        if onthefly.save
          user = find(:first, :conditions => ["login=?", login])
          logger.info("User '#{user.login}' created on the fly.") if logger
        end
      end
    end    
    user.update_attribute(:last_login_on, Time.now) if user
    user
    
    rescue => text
      raise text
  end
	
  # Return user's full name for display
  def display_name
    firstname + " " + lastname
  end
  
  def name
    display_name
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
  
  def role_for_project(project)
    return nil unless project
    member = memberships.detect {|m| m.project_id == project.id}
    member ? member.role : nil 
  end
  
  def authorized_to(project, action)
    return true if self.admin?
    role = role_for_project(project)
    role && Permission.allowed_to_role(action, role)
  end
  
  def pref
    self.preference ||= UserPreference.new(:user => self)
  end
  
  def get_or_create_rss_key
    self.rss_key || Token.create(:user => self, :action => 'feeds')
  end
  
  def self.find_by_rss_key(key)
    token = Token.find_by_value(key)
    token && token.user.active? ? token.user : nil
  end
  
  def self.find_by_autologin_key(key)
    token = Token.find_by_action_and_value('autologin', key)
    token && (token.created_on > Setting.autologin.to_i.day.ago) && token.user.active? ? token.user : nil
  end

  def <=>(user)
    lastname == user.lastname ? firstname <=> user.firstname : lastname <=> user.lastname
  end
  
private
  # Return password digest
  def self.hash_password(clear_password)
    Digest::SHA1.hexdigest(clear_password || "")
  end
end
