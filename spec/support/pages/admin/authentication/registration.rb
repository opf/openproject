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

require "support/pages/page"

module Pages
  module Admin
    module Authentication
      class Registration < ::Pages::Page
        attr_reader :id, :individual_principal

        def path
          admin_settings_authentication_path(tab: "registration")
        end

        def save
          click_button "Save"
          # wait for the save to be processed
          expect_and_dismiss_flash(message: "Successful update.")
        end

        def expect_self_registration_selected(key)
          expect(page).to have_field("settings[self_registration]",
                                     with: Setting::SelfRegistration.value(key:))
        end

        def expect_visible_unsupervised_self_registration_warning
          expect(page).to have_text(I18n.t(:setting_self_registration_warning))
        end

        def expect_hidden_unsupervised_self_registration_warning
          expect(page).to have_no_text(I18n.t(:setting_self_registration_warning))
        end
      end
    end
  end
end
