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

require "support/pages/page"

module Pages
  module Admin
    module EnterpriseTokens
      class Index < ::Pages::Page
        def path
          enterprise_tokens_path
        end

        def add_enterprise_token(token_text)
          click_button "Add Enterprise token"
          modals.expect_modal("Add Enterprise token")
          fill_in "Your Enterprise token text", with: token_text
          click_button "Add"
        end

        def close_welcome_video_modal
          modals.expect_modal("Quick feature overview")
          expect(page).to have_css("#enterprise-trial-welcome-dialog video")
          page.find('[data-close-dialog-id="enterprise-trial-welcome-dialog"]').click
        end

        def expect_add_token_validation_error(message)
          expect(page).to have_dialog("Add Enterprise token")
          expect(page).to have_field("Your Enterprise token text", validation_error: message)
        end

        private

        def modals
          Components::Common::Modal.new
        end
      end
    end
  end
end
