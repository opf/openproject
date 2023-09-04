#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  class Sidebar::DetailsFormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      component_wrapper do
        primer_form_with(
          model: @meeting,
          method: :put,
          url: update_details_meeting_path(@meeting)
        ) do |f|
          component_collection do |collection|
            collection.with_component(Primer::Alpha::Dialog::Body.new) do
              form_content_partial(f)
            end
            collection.with_component(Primer::Alpha::Dialog::Footer.new) do
              form_actions_partial
            end
          end
        end
      end
    end

    def render?
      User.current.allowed_to?(:edit_meetings, @meeting.project)
    end

    private

    def form_content_partial(form)
      flex_layout(my: 3) do |flex|
        flex.with_row do
          render(Meeting::StartDate.new(form, initial_value: start_date_initial_value))
        end
        flex.with_row(mt: 3) do
          render(Meeting::StartTime.new(form, initial_value: start_time_initial_value))
        end
        flex.with_row(mt: 3) do
          render(Meeting::Duration.new(form))
        end
        flex.with_row(mt: 3) do
          render(Meeting::Location.new(form))
        end
      end
    end

    def start_date_initial_value
      @meeting.start_time&.strftime("%Y-%m-%d")
    end

    def start_time_initial_value
      @meeting.start_time&.strftime("%H:%M")
    end

    def form_actions_partial
      component_collection do |collection|
        collection.with_component(Primer::ButtonComponent.new(data: { 'close-dialog-id': "edit-meeting-details-dialog" })) do
          t("button_cancel")
        end
        collection.with_component(Primer::ButtonComponent.new(scheme: :primary, type: :submit)) do
          t("button_save")
        end
      end
    end
  end
end
