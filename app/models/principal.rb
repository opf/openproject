#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Principal < ActiveRecord::Base
  extend Pagination::Model

  self.table_name = "#{table_name_prefix}users#{table_name_suffix}"

  has_many :members, :foreign_key => 'user_id', :dependent => :destroy
  has_many :memberships, :class_name => 'Member', :foreign_key => 'user_id', :include => [ :project, :roles ], :conditions => "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}", :order => "#{Project.table_name}.name"
  has_many :projects, :through => :memberships

  # Groups and active users
  scope :active, :conditions => "#{Principal.table_name}.type='Group' OR (#{Principal.table_name}.type='User' AND #{Principal.table_name}.status = 1)"

  scope :active_or_registered, :conditions => "#{Principal.table_name}.type='Group' OR (#{Principal.table_name}.type='User' AND (#{Principal.table_name}.status = 1 OR #{Principal.table_name}.status = 2))"

  scope :not_in_project, lambda { |project| {:conditions => "id NOT IN (select m.user_id FROM members as m where m.project_id = #{project.id})"}}

  scope :like, lambda {|q|
    concatenation = "((firstname || ' ') || lastname)"
    # special concat for mysql
    if ChiliProject::Database.mysql?
      concatenation = "CONCAT(CONCAT(firstname, ' '), lastname)"
    end
    s = "%#{q.to_s.strip.downcase}%"
    {:conditions => ["LOWER(login) LIKE :s OR LOWER(firstname) LIKE :s OR LOWER(lastname) LIKE :s OR LOWER(#{concatenation}) LIKE :s OR LOWER(mail) LIKE :s", {:s => s}],
     :order => 'type, login, lastname, firstname, mail'
    }
  }

  before_create :set_default_empty_values

  def self.search_scope(query)
    active_or_registered.like(query)
  end

  def name(formatter = nil)
    to_s
  end

  def self.possible_members(criteria, limit)
    Principal.active_or_registered.like(criteria).find(:all, :limit => limit)
  end

  def self.paginate_scope!(scope, options = {})
    limit = options.fetch(:page_limit) || 10
    page = options.fetch(:page) || 1
    scope.paginate({ :per_page => limit, :page => page })
  end

  def self.search_scope_without_project(project, query)
    search_scope(query).not_in_project(project)
  end

  def self.search_scope(query)
    active_or_registered.like(query)
  end

  def status_name
    # Only Users should have another status than active.
    # User defines the status values and other classes like Principal
    # shouldn't know anything about them. Nevertheless, some functions
    # want to know the status for other Principals than User.
    raise "Principal has status other than active" unless self.status == 1
    'active'
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
    self.firstname ||= ''
    self.lastname ||= ''
    self.mail ||= ''
    true
  end
end
