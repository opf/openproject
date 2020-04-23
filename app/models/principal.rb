#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Principal < ApplicationRecord
  # Account statuses
  # Code accessing the keys assumes they are ordered, which they are since Ruby 1.9
  STATUSES = {
    active: 1,
    registered: 2,
    locked: 3,
    invited: 4
  }.freeze

  self.table_name = "#{table_name_prefix}users#{table_name_suffix}"

  has_one :preference,
          dependent: :destroy,
          class_name: 'UserPreference',
          foreign_key: 'user_id'
  has_many :members, foreign_key: 'user_id', dependent: :destroy
  has_many :memberships, -> {
    includes(:project, :roles)
      .where(projects: { active: true })
      .order(Arel.sql('projects.name ASC'))
    # haven't been able to produce the order using hashes
  },
           class_name: 'Member',
           foreign_key: 'user_id'
  has_many :projects, through: :memberships
  has_many :categories, foreign_key: 'assigned_to_id', dependent: :nullify

  scope :active, -> { where(status: STATUSES[:active]) }

  scope :active_or_registered, -> {
    not_builtin.where(status: [STATUSES[:active], STATUSES[:registered], STATUSES[:invited]])
  }

  scope :active_or_registered_like, ->(query) { active_or_registered.like(query) }

  scope :in_project, ->(project) {
    where(id: Member.of(project).select(:user_id))
  }

  scope :not_in_project, ->(project) {
    where.not(id: Member.of(project).select(:user_id))
  }

  scope :not_builtin, -> {
    where.not(type: [SystemUser.name, AnonymousUser.name, DeletedUser.name])
  }

  scope :like, ->(q) {
    firstnamelastname = "((firstname || ' ') || lastname)"
    lastnamefirstname = "((lastname || ' ') || firstname)"

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

  def self.in_visible_project_or_me(user = User.current)
    in_visible_project(user)
      .or(me)
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

  # Helper method to identify internal users
  def builtin?
    false
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

  def <=>(other)
    if self.class.name == other.class.name
      to_s.downcase <=> other.to_s.downcase
    else
      # groups after users
      other.class.name <=> self.class.name
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

  extend Pagination::Model
end
