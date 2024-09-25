#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Meetings
  class UpdateFlashComponent < ApplicationComponent
    include OpTurbo::Streamable

    alias_method :meeting, :model

    def call
      render(
        ::OpPrimer::FlashComponent.new(
          icon: :info,
          dismiss_scheme: :none,
          unique_key: "meetings-update-flash"
        )
      ) do |banner|
        banner.with_action_button(
          tag: :a,
          href: helpers.meeting_path(meeting),
          data: { turbo: false, poll_for_changes_target: "reloadButton" },
          size: :medium
        ) { I18n.t("label_meeting_reload") }

        I18n.t("notice_meeting_updated")
      end
    end
  end
end
