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

module Meetings
  module PresentationComponentStreams
    extend ActiveSupport::Concern

    included do
      def update_content_via_turbo_stream
        update_header_via_turbo_stream
        update_footer_via_turbo_stream
        update_show_via_turbo_stream

        respond_with_turbo_streams
      end

      def update_reference_value(new_reference)
        turbo_streams << turbo_stream.set_dataset_attribute(
          "#op-meeting-presentation-content",
          "reference-value",
          new_reference
        )
      end

      def update_header_via_turbo_stream
        update_via_turbo_stream(
          component: Meetings::PresentationMode::HeaderComponent.new(
            meeting: @meeting,
            current_item: @meeting_agenda_item
          )
        )
      end

      def update_footer_via_turbo_stream
        update_via_turbo_stream(
          component: Meetings::PresentationMode::FooterComponent.new(
            meeting: @meeting,
            sorted_agenda_item_ids:,
            current_item: @meeting_agenda_item,
            current_slide: @current_slide,
            started_at: @started_at
          )
        )
      end

      def update_show_via_turbo_stream
        update_via_turbo_stream(
          component: MeetingAgendaItems::ItemComponent::ShowComponent.new(
            meeting_agenda_item: @meeting_agenda_item,
            current_occurrence: @meeting,
            presentation_mode: true,
            slide: @current_slide
          )
        )
      end
    end
  end
end
