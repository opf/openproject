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

module WorkPackageTab
  class Meetings::ItemComponent < Base::Component
    def initialize(meeting:, active_work_package: nil, **kwargs)
      @meeting = meeting
      @active_work_package = active_work_package
    end

    def call
      flex_layout(justify_content: :space_between, align_items: :flex_start) do |flex|
        flex.with_column do
          content_partial
        end
        flex.with_column do
          actions_partial
        end
      end
    end

    private

    def content_partial
      flex_layout do |flex|
        flex.with_row do
          meeting_date_partial
        end
        flex.with_row(pl: 2, mt: 2) do
          meeting_title_and_author_partial
        end
      end
    end

    def meeting_date_partial
      render(Primer::Beta::Label.new(size: :large)) do 
        "#{format_date(@meeting.start_time)}"
      end
    end

    def meeting_title_and_author_partial
      flex_layout do |flex|
        flex.with_row do
          meeting_title_partial
        end
        # flex.with_row do
        #   author_partial
        # end
      end
    end

    def meeting_title_partial
      flex_layout(align_items: :baseline) do |flex|
        flex.with_column(pr: 1) do
          render(Primer::Beta::Text.new(font_size: :normal, color: :muted, font_weight: :bold)) do
            "Meeting:"
          end
        end
        flex.with_column(pr: 1) do
          render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold)) do 
            "#{@meeting.title}" 
          end
        end
        flex.with_column do
          render(Primer::Beta::Counter.new(
            scheme: :primary, count: count_active_work_package_references_in_meeting || 0, hide_if_zero: true
          ))
        end
      end
    end

    def author_partial
      render(Primer::Beta::Text.new(font_size: :normal, color: :muted, font_weight: :bold)) do
        "created by #{@meeting.author.name}"
      end
    end

    def actions_partial
      form_with( 
        url: show_in_wp_tab_meeting_path(@meeting, work_package_id: @active_work_package&.id), 
        method: :get, 
        data: { "turbo-stream": true } 
      ) do |form| 
          render(Primer::Beta::IconButton.new(
            mr: 2,
            size: :medium,
            disabled: false,
            icon: "arrow-right",
            show_tooltip: true,
            type: :submit,
            "aria-label": "Add to meeting"
          ))
      end
    end
    
    def count_active_work_package_references_in_meeting
      @meeting.agenda_items.where(work_package_id: @active_work_package.id).count if @active_work_package.present?
    end

  end
end
