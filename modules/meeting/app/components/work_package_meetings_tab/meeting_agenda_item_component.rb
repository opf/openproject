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

module WorkPackageMeetingsTab
  class MeetingAgendaItemComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    def initialize(work_package:, meeting_agenda_item:)
      super

      @work_package = work_package
      @meeting_agenda_item = meeting_agenda_item
    end

    def work_package_is_agenda_item?
      @meeting_agenda_item.work_package_id == @work_package.id
    end

    def outcome_heading(outcomes, index)
      heading = t(:label_agenda_outcome)
      heading += " #{index + 1}" if outcomes.size > 1

      heading
    end

    def work_package_outcome_text(outcome) # rubocop:disable Metrics/AbcSize
      if outcome.visible_work_package?
        concat render(Primer::Box.new(classes: "op-uc-container", pb: 0, mt: 1)) {
          flex_layout do |flex|
            flex.with_row do
              render(WorkPackages::InfoLineComponent.new(work_package: outcome.work_package))
            end
            flex.with_row do
              render(
                Primer::Beta::Link.new(
                  href: work_package_path(outcome.work_package),
                  font_size: :normal,
                  font_weight: :bold
                )
              ) { outcome.work_package.subject }
            end
          end
        }
      elsif outcome.linked_work_package?
        concat render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) {
          I18n.t(:label_agenda_item_undisclosed_wp, id: outcome.work_package_id)
        }
      elsif outcome.deleted_work_package?
        concat render(Primer::Beta::Text.new(font_size: :small, color: :danger, tag: :s)) {
          I18n.t(:label_agenda_item_deleted_wp)
        }
      end
    end
  end
end
