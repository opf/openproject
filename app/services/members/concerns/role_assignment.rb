# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

module Members::Concerns::RoleAssignment
  private

  def set_attributes(params)
    assign_roles(params)

    super
  end

  def assign_roles(params)
    raise ArgumentError, 'Cannot handle changing `roles`. Use role_ids instead.' if model.persisted? && params.key?(:roles)

    return unless params[:role_ids]

    role_ids = params
                 .delete(:role_ids)
                 .select(&:present?)
                 .map(&:to_i)

    mark_roles_for_destruction(existing_ids - role_ids)
    build_roles(role_ids - existing_ids)
  end

  def existing_ids
    model.member_roles.map(&:role_id)
  end

  def mark_roles_for_destruction(role_ids)
    role_ids.each do |role_id|
      model
        .member_roles
        .detect { |mr| mr.inherited_from.nil? && mr.role_id == role_id }
        &.mark_for_destruction
    end
  end

  def build_roles(role_ids)
    role_ids.each do |role_id|
      model.member_roles.build(role_id:)
    end
  end
end
