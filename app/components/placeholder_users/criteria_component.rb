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

module PlaceholderUsers
  # The criteria tab: the switch activating them, the filter builder they are
  # edited in, and the users they currently select.
  class CriteriaComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include OpPrimer::FormHelpers

    # Primer's sidebar widths stop at 336px, which leaves the matching users
    # cramped next to the criteria.
    SIDEBAR_WIDTH = "--Layout-sidebar-width: 30rem"

    # Criteria are active as long as any are stored. `active` covers the step in
    # between: the switch has just been turned on and the builder is offered
    # before anything is saved.
    def initialize(placeholder_user:, active: placeholder_user.user_filter.present?)
      super

      @placeholder_user = placeholder_user
      @active = active
    end

    private

    attr_reader :placeholder_user

    def active?
      @active
    end

    def title
      I18n.t("placeholder_users.criteria.activate")
    end

    def caption
      I18n.t("placeholder_users.criteria.activate_caption")
    end

    def form_url
      placeholder_user_path(placeholder_user, tab: :criteria)
    end

    def live_update_path
      update_criteria_placeholder_user_path(placeholder_user)
    end

    def toggle_arguments
      {
        name: :criteria_active,
        label: title,
        caption:,
        src: toggle_criteria_placeholder_user_path(placeholder_user),
        csrf_token: helpers.form_authenticity_token,
        checked: active?,
        status_label_position: :start,
        data: { turbo: true, test_selector: "placeholder-user-criteria-toggle" }
      }
    end
  end
end
