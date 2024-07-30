# -- copyright
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
# ++

require_relative "../../sharing/share_modal"

module Components
  module Sharing
    module ProjectQueries
      class ShareModal < Components::Sharing::ShareModal
        # rubocop:disable Lint/MissingSuper
        def initialize(project_query)
          @entity = project_query
          @title = I18n.t(:label_share_project_list)
        end
        # rubocop:enable Lint/MissingSuper

        def expect_unable_to_manage(only_invite: false)
          expect(page).to have_no_css("[data-test-selector='invite-user-form']")
          expect(page).to have_css("[data-tooltip=\"You don't have permissions to share Project lists.\"]") unless only_invite
        end

        def close
          # Tooltips interfere with the driver's ability
          # to fire a click event. Using node#trigger
          find(".Overlay-closeButton").trigger("click")
        end

        def toggle_public
          find("toggle-switch").click
        end

        def expect_toggle_public_disabled
          within("toggle-switch") do
            expect(find("button")).to be_disabled
          end
        end

        def expect_upsale_banner
          expect(page).to have_css("[data-test-selector='op-share-dialog-upsale-block']")
        end
      end
    end
  end
end
