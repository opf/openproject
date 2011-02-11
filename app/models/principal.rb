#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Principal < ActiveRecord::Base
  set_table_name "#{table_name_prefix}users#{table_name_suffix}"

  has_many :members, :foreign_key => 'user_id', :dependent => :destroy
  has_many :memberships, :class_name => 'Member', :foreign_key => 'user_id', :include => [ :project, :roles ], :conditions => "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}", :order => "#{Project.table_name}.name"
  has_many :projects, :through => :memberships

  # Groups and active users
  named_scope :active, :conditions => "#{Principal.table_name}.type='Group' OR (#{Principal.table_name}.type='User' AND #{Principal.table_name}.status = 1)"

  named_scope :active_or_registered, :conditions => "#{Principal.table_name}.type='Group' OR (#{Principal.table_name}.type='User' AND (#{Principal.table_name}.status = #{User::STATUS_ACTIVE} OR #{Principal.table_name}.status = #{User::STATUS_REGISTERED}))"
  
  named_scope :like, lambda {|q|
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(login) LIKE :s OR LOWER(firstname) LIKE :s OR LOWER(lastname) LIKE :s OR LOWER(mail) LIKE :s", {:s => s}],
     :order => 'type, login, lastname, firstname, mail'
    }
  }

  before_create :set_default_empty_values

  def name(formatter = nil)
    to_s
  end

  def self.possible_members(criteria, limit)
    Principal.active_or_registered.like(criteria).find(:all, :limit => limit)
  end

  def <=>(principal)
    if self.class.name == principal.class.name
      self.to_s.downcase <=> principal.to_s.downcase
    else
      # groups after users
      principal.class.name <=> self.class.name
    end
  end

  protected

  # Make sure we don't try to insert NULL values (see #4632)
  def set_default_empty_values
    self.login ||= ''
    self.hashed_password ||= ''
    self.firstname ||= ''
    self.lastname ||= ''
    self.mail ||= ''
    true
  end
end
