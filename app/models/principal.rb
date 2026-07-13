# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
  include HasDetailsTable

  default_scope -> { where.not(status: Principal.statuses[:deleted]) }

  # Account statuses
  # Disables enum scopes to include not_builtin (cf. Principals::Scopes::Status)
  enum :status, {
    active: 1,
    registered: 2,
    locked: 3,
    invited: 4,
    deleted: 5
  }, scopes: false

  self.table_name = "#{table_name_prefix}users#{table_name_suffix}"

  has_one :preference,
          dependent: :destroy,
          class_name: "UserPreference",
          foreign_key: "user_id",
          inverse_of: :user
  has_many :members, foreign_key: "user_id", dependent: :destroy, inverse_of: :principal
  has_many :memberships,
           -> {
             includes(:project, :roles)
               .merge(Member.of_any_project.or(Member.global))
               .where(["projects.active = ? OR members.project_id IS NULL", true])
               .order(Arel.sql("projects.name ASC"))
           },
           inverse_of: :principal,
           dependent: :nullify,
           class_name: "Member",
           foreign_key: "user_id"
  has_many :work_package_shares,
           -> { where(entity_type: WorkPackage.name) },
           inverse_of: :principal,
           dependent: :delete_all,
           class_name: "Member",
           foreign_key: "user_id"
  has_many :projects, through: :memberships
  has_many :categories, foreign_key: "assigned_to_id", dependent: :nullify, inverse_of: :assigned_to
  has_many :user_auth_provider_links,
           dependent: :destroy,
           foreign_key: :user_id,
           inverse_of: :principal
  has_many :auth_providers, through: :user_auth_provider_links

  has_many :persisted_views, inverse_of: :principal, dependent: :nullify
  has_many :persisted_queries, inverse_of: :principal, dependent: :nullify

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

    sql_condition = group_id.any? ? "WHERE gu.group_id IN (?)" : ""
    sql_not = positive ? "" : "NOT"

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

  self.ignored_columns += [:identity_url]

  # Columns required for formatting the principal's name.
  def self.columns_for_name(formatter = nil)
    raise SubclassResponsibilityError, "Redefine in subclass" unless self == Principal

    [User, Group, PlaceholderUser].map { it.columns_for_name(formatter) }.inject(:|)
  end

  # Select columns for formatting the user's name.
  def self.select_for_name(formatter = nil)
    select(*columns_for_name(formatter))
  end

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

  def self.in_visible_project_or_me_or_same_groups(user = User.current)
    in_visible_project(user)
      .or(me)
      .or(in_same_groups(user))
  end

  def self.in_same_groups(user = User.current)
    group_ids = user.group_ids
    return none if group_ids.empty?

    where(id: GroupUser.where(group_id: group_ids).select(:user_id))
  end

  def active_user_auth_provider_link
    # note: order("updated_at") is not used, because it returns nil if relation is not persisted
    user_auth_provider_links.max_by(&:updated_at)
  end

  def identity_url
    link = active_user_auth_provider_link
    "#{link.auth_provider.slug}:#{link.external_id}" if link.present?
  end

  def authentication_provider
    active_user_auth_provider_link&.auth_provider
  end

  # Helper method to identify internal users
  def builtin?
    false
  end

  ##
  # Allows the API and other sources to determine locking actions
  # on represented collections of children of Principals.
  # Must be overridden by descendants
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

  # Returns true if usr or current user is allowed to view the user
  def visible?(usr = User.current)
    User.visible(usr).exists?(id: id)
  end

  def <=>(other)
    if instance_of?(other.class)
      to_s.downcase <=> other.to_s.downcase
    else
      # groups after users
      other.class.name <=> self.class.name
    end
  end

  def scim_external_id
    active_user_auth_provider_link&.external_id
  end

  def scim_external_id=(external_id)
    oidc_provider = User.current.service_account_association.service.auth_provider

    "::#{self.class}s::SetAttributesService"
      .constantize
      .new(user: User.current, model: self, contract_class: EmptyContract)
      .call(identity_url: "#{oidc_provider.slug}:#{external_id}")
      .on_failure { |result| raise result.to_s }
    external_id
  end

  class << self
    def scim_mutable_attributes
      # Allow mutation of everything with a write accessor
      nil
    end

    def scim_timestamps_map
      {
        created: :created_at,
        lastModified: :updated_at
      }
    end

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
    self.login ||= ""
    self.firstname ||= ""
    self.lastname ||= ""
    self.mail ||= ""
    true
  end
end
