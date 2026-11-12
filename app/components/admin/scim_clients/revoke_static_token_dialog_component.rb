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

module Admin
  module ScimClients
    class RevokeStaticTokenDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      TEST_SELECTOR = "op-scim-clients--revoke-static-token-dialog"

      def initialize(model, scim_client_id:, turbo_frame: nil)
        super(model)

        @scim_client_id = scim_client_id
        @turbo_frame = turbo_frame
      end

      def form_arguments
        {
          action: admin_scim_client_static_token_path(model, scim_client_id: @scim_client_id),
          method: :delete
        }.merge(turbo_frame_arguments)
      end

      def turbo_frame_arguments
        return {} if @turbo_frame.nil?

        { data: { turbo_frame: @turbo_frame } }
      end
    end
  end
end
