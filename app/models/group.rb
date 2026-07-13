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

class Group < Principal
  include ::Scopes::Scoped
  include Groups::Hierarchy

  attr_accessor :hierarchy_depth

  has_details_table(foreign_key: :principal_id) do
    belongs_to :parent, class_name: "Group", optional: true

    validates :parent, presence: true, if: -> { parent_id.present? }
  end

  validate :no_circular_parent, if: -> { parent_id.present? }
  validate :no_organizational_unit_mismatch, if: -> { parent_id.present? }

  # Register a partial to be rendered on the synchronized groups tab of the groups admin page
  #
  # @param title[String] I18n key that will be used as a title for the section
  # @param partial[String] The partial path as it would be passed to `render partial:` for the partial that renders
  #                        a list of synchronized groups to the group
  def self.add_synchronized_group_partial(title:, partial:, count_callback:)
    synchronized_group_partials.push(title:, partial:, count_callback:)
  end

  def self.synchronized_group_partials
    @synchronized_group_partials ||= []
  end

  # Register a predicate that determines whether a group is managed by an external synchronization
  # (e.g. the LDAP department sync). Modules register their own check so the core stays agnostic of
  # them; when no module is loaded a group is never considered managed.
  #
  # @yieldparam group[Group] the group to check
  # @yieldreturn [Boolean] whether the group is managed by that source
  def self.register_ldap_managed_check(&block)
    ldap_managed_checks.push(block)
  end

  def self.ldap_managed_checks
    @ldap_managed_checks ||= []
  end

  has_many :group_users,
           autosave: true,
           dependent: :destroy

  has_many :users,
           through: :group_users,
           before_add: :fail_add

  has_many :synchronized_groups,
           class_name: "::LdapGroups::SynchronizedGroup",
           dependent: :destroy

  acts_as_customizable

  alias_attribute(:name, :lastname)
  validates :name, presence: true
  validate :uniqueness_of_name
  validates :name, length: { maximum: 256 }

  # HACK: We want to have the :preference association on the Principal to allow
  # for eager loading preferences.
  # However, the preferences are currently very user specific.  We therefore
  # remove the methods added by
  #   has_one :preference
  # to avoid accidental assignment and usage of preferences on groups.
  undef_method :preference,
               :preference=,
               :build_preference,
               :create_preference,
               :create_preference!

  scopes :visible, :containing_user, :organizational_units

  # Whether this group is managed by an external synchronization (e.g. LDAP department sync).
  # Managed departments are read-only in the admin UI and may only be changed by the sync itself.
  def ldap_managed?
    self.class.ldap_managed_checks.any? { |check| check.call(self) }
  end

  # Columns required for formatting the group's name.
  def self.columns_for_name(_formatter = nil)
    [:lastname]
  end

  def to_s
    lastname
  end

  def scim_members
    @scim_members ||= users
  end

  def scim_members=(array)
    # Here we just assign array of found users to an instance variable.
    # So it is done on a higher(controller) level to pass users_ids list
    # to Groups::UpdateService
    @scim_members = array
  end

  def self.scim_resource_type
    Scimitar::Resources::Group
  end

  def self.scim_attributes_map
    {
      id: :id,
      externalId: :scim_external_id,
      displayName: :name,
      members: [
        {
          list: :scim_members,
          using: {
            value: :id
          },
          find_with: ->(scim_list_entry) {
            id   = scim_list_entry["value"]
            type = scim_list_entry["type"] || "User" # Some online examples omit 'type' and believe 'User' will be assumed

            case type.downcase
            when "user"
              User.not_builtin.find_by(id:)
            when "group"
              # OP does not support nesting of groups but SCIM does.
              # For now raises exception in case of group as a member arrival.
              raise Scimitar::InvalidSyntaxError.new("Unsupported type #{type.inspect}")
            else
              raise Scimitar::InvalidSyntaxError.new("Unrecognised type #{type.inspect}")
            end
          }
        }
      ]
    }
  end

  def self.scim_queryable_attributes
    {
      displayName: { column: :lastname },
      externalId: { column: UserAuthProviderLink.arel_table[:external_id] }
    }
  end

  include Scimitar::Resources::Mixin

  private

  def uniqueness_of_name
    scope = Group.where(lastname: name).where.not(id: id || 0)

    # Regular groups must be globally unique. Organizational units (departments) only need to be
    # unique among their siblings: LDAP directories routinely repeat the same OU name on different
    # branches (e.g. OU=Support under both IT and HR), so we scope uniqueness to the parent.
    scope = if organizational_unit?
              scope.where_detail(organizational_unit: true, parent_id:)
            else
              scope.where_detail(organizational_unit: false)
            end

    errors.add(:name, :taken) if scope.exists?
  end

  def fail_add
    fail "Do not add users through association, use `Groups::AddUsersService` instead."
  end

  def no_circular_parent
    if parent_id == id || descendant_ids.include?(parent_id)
      errors.add(:parent_id, :circular_dependency)
    end
  end

  def no_organizational_unit_mismatch
    parent = self.class.find_by(id: parent_id)
    return unless parent

    if organizational_unit? != parent.organizational_unit?
      errors.add(:parent_id, :organizational_unit_mismatch)
    end
  end
end
