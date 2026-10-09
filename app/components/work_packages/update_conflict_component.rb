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

module WorkPackages
  class UpdateConflictComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def initialize(scheme: :warning, button_text: I18n.t("label_meeting_reload"))
      super

      @scheme = scheme
      @button_text = button_text

      if %i[warning danger].exclude?(@scheme)
        raise ArgumentError, "Invalid scheme: #{@scheme}. Must be :warning or :danger."
      end
    end

    def call
      render(
        ::OpPrimer::FlashComponent.new(
          scheme: @scheme,
          icon: @scheme == :danger ? :stop : :"alert-fill",
          dismiss_scheme: :hide,
          unique_key: "work-package-update-conflict",
          data: {
            "banner-scheme": @scheme.to_s # used for testing
          }
        )
      ) do |banner|
        banner.with_action_button(
          tag: :a,
          href: "#",
          data: {
            turbo: false,
            action: "click->flash#reloadPage",
            test_selector: "op-work-package-update-conflict-reload-button"
          },
          size: :medium
        ) { @button_text }

        content
      end
    end
  end
end
