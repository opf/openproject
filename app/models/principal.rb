#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Principal < ApplicationRecord
  include ::Scopes::Scoped

  # Account statuses
  # Disables enum scopes to include not_builtin (cf. Principals::Scopes::Status)
  enum status: {
    active: 1,
    registered: 2,
    locked: 3,
    invited: 4
  }.freeze, _scopes: false

  self.table_name = "#{table_name_prefix}users#{table_name_suffix}"

  has_one :preference,
          dependent: :destroy,
          class_name: 'UserPreference',
          foreign_key: 'user_id',
          inverse_of: :user
  has_many :members, foreign_key: 'user_id', dependent: :destroy, inverse_of: :principal
  has_many :memberships,
           -> {
             includes(:project, :roles)
               .merge(Member.of_any_project.or(Member.global))
               .where(["projects.active = ? OR members.project_id IS NULL", true])
               .order(Arel.sql('projects.name ASC'))
           },
           inverse_of: :principal,
           dependent: :nullify,
           class_name: 'Member',
           foreign_key: 'user_id'
  has_many :work_package_shares,
           -> { where(entity_type: WorkPackage.name) },
           inverse_of: :principal,
           dependent: :delete_all,
           class_name: 'Member',
           foreign_key: 'user_id'
  has_many :projects, through: :memberships
  has_many :categories, foreign_key: 'assigned_to_id', dependent: :nullify, inverse_of: :assigned_to

  has_paper_trail

  scopes :like,
         :having_entity_membership,
         :human,
         :not_builtin,
         :possible_assignee,
         :possible_member,
         :user,
         :ordered_by_name,
         :visible,
         :status

  scope :in_project, ->(project) {
    where(id: Member.of_project(project).select(:user_id))
  }

  scope :not_in_project, ->(project) {
    where.not(id: Member.of_project(project).select(:user_id))
  }

  scope :in_anything_in_project, ->(project) {
    where(id: Member.of_anything_in_project(project).select(:user_id))
  }

  scope :not_in_anything_in_project, ->(project) {
    where.not(id: Member.of_anything_in_project(project).select(:user_id))
  }

  scope :in_group, ->(group) {
    within_group(group)
  }

  scope :not_in_group, ->(group) {
    within_group(group, false)
  }

  scope :within_group, ->(group, positive = true) {
    group_id = group.is_a?(Group) ? [group.id] : Array(group).map(&:to_i)

    sql_condition = group_id.any? ? 'WHERE gu.group_id IN (?)' : ''
    sql_not = positive ? '' : 'NOT'

    sql_query = [
      "#{User.table_name}.id #{sql_not} IN " \
      "(SELECT gu.user_id FROM #{table_name_prefix}group_users#{table_name_suffix} gu #{sql_condition})"
    ]
    if group_id.any?
      sql_query.push group_id
    end

    where(sql_query)
  }

  before_create :set_default_empty_values

  def name(_formatter = nil)
    to_s
  end

  def self.search_scope_without_project(project, query)
    not_locked.like(query).not_in_project(project)
  end

  def self.me
    where(id: User.current.id)
  end

  def self.in_visible_project(user = User.current)
    where(id: Member.of_anything_in_project(Project.visible(user)).select(:user_id))
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
    if instance_of?(other.class)
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
      sti_names = ([self] + descendants).filter_map(&:sti_name)

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
end
