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
  class Sidebar::StateComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      component_wrapper do
        flex_layout do |flex|
          flex.with_row do
            state_label_partial
          end
          flex.with_row(mt: 3) do
            description_partial
          end
          flex.with_row(mt: 2) do
            actions_partial
          end
        end
      end
    end

    private

    def state_label_partial
      render(Primer::Beta::State.new(title: "state", scheme: :open)) do
        flex_layout do |flex|
          flex.with_column(mr: 1) do
            render(Primer::Beta::Octicon.new(icon: "issue-opened"))
          end
          flex.with_column do
            render(Primer::Beta::Text.new) { "Open" }
          end
        end
      end
    end

    def description_partial
      render(Primer::Beta::Text.new(color: :subtle)) do
        "This meeting is open. You can add/remove agenda items and edit them as you please. After the meeting is over, close it to lock it."
      end
    end

    def actions_partial
      render(Primer::Beta::Button.new(scheme: :invisible)) do |button|
        button.with_leading_visual_icon(icon: :lock)
        "Close meeting (to-do)"
      end
    end
  end
end
