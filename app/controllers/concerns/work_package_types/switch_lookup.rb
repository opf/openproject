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

module WorkPackageTypes
  # A switch and its impact are two endpoints onto the same choice, so both resolve the
  # member being switched away from the same way.
  module SwitchLookup
    private

    # The row names the member in force, which is the variant when the project resolves one, so
    # the type is looked up globally and checked against the families the project uses. It is
    # then resolved again: on a page left open across a switch, the id names a member the
    # project has since moved off.
    def load_source
      type = ::Type.find_by(id: params[:type_id])
      @source = @project.type_variant(type) if type && @project.project_types.exists?(type_id: type.id)

      return if @source

      render_error_flash_message_via_turbo_stream(message: t("projects.settings.types.type_not_found"))
      respond_to_with_turbo_streams(status: :unprocessable_entity)
    end
  end
end
