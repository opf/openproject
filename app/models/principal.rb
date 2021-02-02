#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Principal < ApplicationRecord
  include ::Scopes::Scoped

  # Account statuses
  enum status: {
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
      .where(["projects.active = ? OR project_id IS NULL", true])
      .order(Arel.sql('projects.name ASC'))
    # haven't been able to produce the order using hashes
  },
           class_name: 'Member',
           foreign_key: 'user_id'
  has_many :projects, through: :memberships
  has_many :categories, foreign_key: 'assigned_to_id', dependent: :nullify

  scope_classes Principals::Scopes::NotBuiltin,
                Principals::Scopes::User,
                Principals::Scopes::Human,
                Principals::Scopes::Like,
                Principals::Scopes::PossibleMember,
                Principals::Scopes::PossibleAssignee

  scope :not_locked, -> {
    not_builtin.where.not(status: statuses[:locked])
  }

  scope :in_project, ->(project) {
    where(id: Member.of(project).select(:user_id))
  }

  scope :not_in_project, ->(project) {
    where.not(id: Member.of(project).select(:user_id))
  }

  before_create :set_default_empty_values

  def name(_formatter = nil)
    to_s
  end

  def self.search_scope_without_project(project, query)
    not_locked.like(query).not_in_project(project)
  end

  def self.order_by_name
    order(User::USER_FORMATS_STRUCTURE[Setting.user_format].map { |format| "#{Principal.table_name}.#{format}" })
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

  # Helper method to identify internal users
  def builtin?
    false
  end

  ##
  # Allows the API and other sources to determine locking actions
  # on represented collections of children of Principals.
  # Must be overridden by User
  def lockable?
    false
  end

  ##
  # Allows the API and other sources to determine unlocking actions
  # on represented collections of children of Principals.
  # Must be overridden by User
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

  class << self
    # Hack to exclude the Users::InexistentUser
    # from showing up on filters for type.
    # The method is copied over from rails changed only
    # by the #compact call.
    def type_condition(table = arel_table)
      sti_column = table[inheritance_column]
      sti_names  = ([self] + descendants).map(&:sti_name).compact

      predicate_builder.build(sti_column, sti_names)
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
