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
  class ShowComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      flex_layout(data: { turbo: true }) do |flex|
        flex.with_row do
          # prototyical usage of Primer's flash message component wrapped in a component which can be updated via turbo stream
          # empty initially
          # should become part of the application layout once finalized
          render(FlashMessageComponent.new)
        end
        flex.with_row(mt: 2, mb: 3, pb: 2, border: :bottom) do
          heading_partial
        end
        flex.with_row do
          main_content_partial
        end
      end
    end

    private

    def heading_partial
      render(Meetings::HeaderComponent.new(meeting: @meeting))
    end

    def main_content_partial
      render(Primer::Alpha::Layout.new(stacking_breakpoint: :lg)) do |component|
        component.with_main { agenda_partial }
        component.with_sidebar(row_placement: :end, col_placement: :end, width: :wide) { sidebar_partial }
      end
    end

    def agenda_partial
      flex_layout do |flex|
        flex.with_row do
          render(MeetingAgendaItems::ListComponent.new(meeting: @meeting))
        end
        flex.with_row do
          render(MeetingAgendaItems::NewButtonComponent.new(meeting: @meeting))
        end
      end
    end

    def sidebar_partial
      render(Meetings::SidebarComponent.new(meeting: @meeting))
    end
  end
end
