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
        case @meeting.state
        when "open"
          open_state_partial
        when "closed"
          closed_state_partial
        end
      end
    end

    private

    def edit_enabled?
      User.current.allowed_to?(:close_meeting_agendas, @meeting.project)
    end

    def open_state_partial
      flex_layout do |flex|
        flex.with_row do
          open_state_label_partial
        end
        flex.with_row(mt: 3) do
          open_description_partial
        end
        if edit_enabled?
          flex.with_row(mt: 3) do
            open_actions_partial
          end
        end
      end
    end

    def open_state_label_partial
      render(Primer::Beta::State.new(title: "state", scheme: :open)) do
        flex_layout do |flex|
          flex.with_column(mr: 1) do
            render(Primer::Beta::Octicon.new(icon: "issue-opened"))
          end
          flex.with_column do
            render(Primer::Beta::Text.new) { t("label_meeting_state_open") }
          end
        end
      end
    end

    def open_description_partial
      render(Primer::Beta::Text.new(color: :subtle)) do
        t("text_meeting_open_description")
      end
    end

    def open_actions_partial
      form_for(@meeting, method: "put", url: change_state_meeting_path(@meeting),
                         data: { 'turbo-stream': true }) do |f|
        flex_layout do |flex|
          flex.with_row do
            f.hidden_field :state, value: "closed"
          end
          flex.with_row do
            render(Primer::Beta::Button.new(
                     scheme: :link,
                     color: :default,
                     underline: false,
                     font_weight: :bold,
                     type: :submit
                   )) do |button|
              button.with_leading_visual_icon(icon: :lock)
              t("label_meeting_close_action")
            end
          end
        end
      end
    end

    def closed_state_partial
      flex_layout do |flex|
        flex.with_row do
          closed_state_label_partial
        end
        flex.with_row(mt: 3) do
          closed_description_partial
        end
        if edit_enabled?
          flex.with_row(mt: 3) do
            closed_actions_partial
          end
        end
      end
    end

    def closed_state_label_partial
      render(Primer::Beta::State.new(title: "state", scheme: :default)) do
        flex_layout do |flex|
          flex.with_column(mr: 1) do
            render(Primer::Beta::Octicon.new(icon: "issue-closed"))
          end
          flex.with_column do
            render(Primer::Beta::Text.new) { t("label_meeting_state_closed") }
          end
        end
      end
    end

    def closed_description_partial
      render(Primer::Beta::Text.new(color: :subtle)) do
        t("text_meeting_closed_description")
      end
    end

    def closed_actions_partial
      form_for(@meeting, method: "put", url: change_state_meeting_path(@meeting),
                         data: { 'turbo-stream': true }) do |f|
        flex_layout do |flex|
          flex.with_row do
            f.hidden_field :state, value: "open"
          end
          flex.with_row do
            render(Primer::Beta::Button.new(
                     scheme: :link,
                     color: :default,
                     underline: false,
                     font_weight: :bold,
                     type: :submit
                   )) do |button|
              button.with_leading_visual_icon(icon: :unlock)
              t("label_meeting_reopen_action")
            end
          end
        end
      end
    end
  end
end
