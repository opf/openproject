#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class Principal < ActiveRecord::Base
  extend Pagination::Model

  # Account statuses
  # Code accessing the keys assumes they are ordered, which they are since Ruby 1.9
  STATUSES = {
    builtin: 0,
    active: 1,
    registered: 2,
    locked: 3,
    invited: 4
  }

  self.table_name = "#{table_name_prefix}users#{table_name_suffix}"

  has_one :preference,
    dependent: :destroy,
    class_name: 'UserPreference',
    foreign_key: 'user_id'
  has_many :members, foreign_key: 'user_id', dependent: :destroy
  has_many :memberships, -> {
    includes(:project, :roles)
      .where(projects: { status: Project::STATUS_ACTIVE })
      .order('projects.name ASC')
    # haven't been able to produce the order using hashes
  },
           class_name: 'Member',
           foreign_key: 'user_id'
  has_many :projects, through: :memberships
  has_many :categories, foreign_key: 'assigned_to_id', dependent: :nullify

  scope :active, -> { where(status: STATUSES[:active]) }

  scope :active_or_registered, -> {
    where(status: [STATUSES[:active], STATUSES[:registered], STATUSES[:invited]])
  }

  scope :active_or_registered_like, ->(query) { active_or_registered.like(query) }

  scope :in_project, ->(project) {
    projects = Array(project)
    subquery = "SELECT DISTINCT user_id FROM members WHERE project_id IN (?)"
    condition = ["#{Principal.table_name}.id IN (#{subquery})",
                 projects.map(&:id)]

    where(condition)
  }

  scope :not_in_project, ->(project) {
    where("id NOT IN (select m.user_id FROM members as m where m.project_id = #{project.id})")
  }

  # Active non-anonymous principals scope
  scope :not_builtin, -> {
    where("#{Principal.table_name}.status <> #{STATUSES[:builtin]}")
  }

  scope :like, -> (q) {
    firstnamelastname = "((firstname || ' ') || lastname)"
    lastnamefirstname = "((lastname || ' ') || firstname)"

    # special concat for mysql
    if OpenProject::Database.mysql?
      firstnamelastname = "CONCAT(CONCAT(firstname, ' '), lastname)"
      lastnamefirstname = "CONCAT(CONCAT(lastname, ' '), firstname)"
    end

    s = "%#{q.to_s.downcase.strip.tr(',', '')}%"

    where(['LOWER(login) LIKE :s OR ' +
             "LOWER(#{firstnamelastname}) LIKE :s OR " +
             "LOWER(#{lastnamefirstname}) LIKE :s OR " +
             'LOWER(mail) LIKE :s',
           { s: s }])
      .order(:type, :login, :lastname, :firstname, :mail)
  }

  before_create :set_default_empty_values

  def name(_formatter = nil)
    to_s
  end

  def self.possible_members(criteria, limit)
    Principal.active_or_registered_like(criteria).limit(limit)
  end

  def self.search_scope_without_project(project, query)
    active_or_registered_like(query).not_in_project(project)
  end

  def self.order_by_name
    order(User::USER_FORMATS_STRUCTURE[Setting.user_format].map(&:to_s))
  end

  def self.me
    where(id: User.current.id)
  end

  def self.in_visible_project(user = User.current)
    in_project(Project.visible(user))
  end

  def status_name
    # Only Users should have another status than active.
    # User defines the status values and other classes like Principal
    # shouldn't know anything about them. Nevertheless, some functions
    # want to know the status for other Principals than User.
    raise 'Principal has status other than active' unless status == STATUSES[:active]
    'active'
  end

  def active_or_registered?
    [STATUSES[:active], STATUSES[:registered], STATUSES[:invited]].include?(status)
  end

  ##
  # Allows the API and other sources to determine locking actions
  # on represented collections of children of Principals.
  # Must be overriden by User
  def lockable?
    false
  end

  ##
  # Allows the API and other sources to determine unlocking actions
  # on represented collections of children of Principals.
  # Must be overriden by User
  def activatable?
    false
  end

  def <=>(principal)
    if self.class.name == principal.class.name
      to_s.downcase <=> principal.to_s.downcase
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
