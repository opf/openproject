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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class MemberRole < ApplicationRecord
  belongs_to :member, touch: true
  belongs_to :role

  after_destroy_commit :cleanup_associated_custom_values

  # `inherited` is reserved ActiveRecord method
  scope :only_inherited, -> { where.not(inherited_from: nil) }
  scope :only_non_inherited, -> { where(inherited_from: nil) }

  validates :role, presence: true
  validate :validate_project_member_role

  def validate_project_member_role
    errors.add :role_id, :invalid if role && !role.member?
  end

  def inherited?
    !inherited_from.nil?
  end

  private

  def cleanup_associated_custom_values
    custom_fields_associated_with_roles = CustomFieldsRole.where(role_id: role_id).pluck(:custom_field_id)

    CustomValue
      .where(
        customized: member.project,
        custom_field_id: custom_fields_associated_with_roles,
        value: member.user_id.to_s
      ).destroy_all
  end
end
