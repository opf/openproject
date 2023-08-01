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
  class Issues::ItemComponent < Base::Component
    def initialize(issue:, called_from_meeting: nil)
      super

      @issue = issue
      @called_from_meeting = called_from_meeting
    end

    def call
      flex_layout(justify_content: :space_between, align_items: :flex_start) do |flex|
        flex.with_column do
          content_partial
        end
        unless @called_from_meeting
          flex.with_column do
            actions_partial
          end
        end
      end
    end

    private

    def content_partial
      flex_layout do |flex|
        flex.with_column(mr: 2) do
          issue_symbol_partial
        end
        flex.with_column do
          issue_description_partial
        end
      end
    end

    def issue_symbol_partial
      if @issue.open?
        render(Primer::Beta::Octicon.new(icon: "issue-opened", 'aria-label': "open", color: :muted))
      else
        render(Primer::Beta::Octicon.new(icon: "issue-closed", 'aria-label': "closed", color: :muted))
      end
    end

    def issue_description_partial
      flex_layout do |flex|
        flex.with_row(flex_layout: true) do |flex|
          flex.with_column(mr: 1) do
            if @issue.open?
              open_issue_type_label_partial
            else
              closed_issue_type_label_partial
            end
          end
          flex.with_column do
            issue_meta_info_partial
          end
        end
        flex.with_row(mt: 2, mb: 1, pl: 0) do
          description_partial
        end
        if @issue.meeting_agenda_items.any? && !@called_from_meeting
          @issue.meeting_agenda_items.each do |meeting_agenda_item|
            flex.with_row(mt: 1, pl: 0) do
              meeting_assignment_partial(meeting_agenda_item)
            end
          end
        end
      end
    end

    def issue_meta_info_partial
      flex_layout do |flex|
        flex.with_column(mr: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :muted)) do
            if @issue.open?
              "by #{@issue.author.name}"
            else
              "by #{@issue.resolved_by&.name}"
            end
          end
        end
        flex.with_column do
          render(Primer::Beta::RelativeTime.new(datetime: @issue.updated_at, font_size: :small, color: :muted))
        end
      end
    end

    def open_issue_type_label_partial
      case @issue.issue_type
      when "input_need"
        render(Primer::Beta::Label.new(scheme: :accent)) { "Input need" }
      when "clarification_need"
        render(Primer::Beta::Label.new(scheme: :attention)) { "Clarification need" }
      when "decision_need"
        render(Primer::Beta::Label.new(scheme: :severe)) { "Decision need" }
      end
    end

    def closed_issue_type_label_partial
      case @issue.issue_type
      when "input_need"
        render(Primer::Beta::Label.new(scheme: :accent)) { "Input" }
      when "clarification_need"
        render(Primer::Beta::Label.new(scheme: :attention)) { "Clarification" }
      when "decision_need"
        render(Primer::Beta::Label.new(scheme: :severe)) { "Decision" }
      end
    end

    def actions_partial
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", 'aria-label': "Issue actions")
        edit_action_item(menu)
        delete_action_item(menu)
        resolve_action_item(menu)
        reopen_action_item(menu)
        add_to_meeting_action_item(menu)
      end
    end

    def edit_action_item(menu)
      return unless @issue.open?

      menu.with_item(label: "Edit", href: edit_work_package_issue_path(work_package_id: @issue.work_package.id, id: @issue.id))
    end

    def delete_action_item(menu)
      return unless @issue.open?

      menu.with_item(label: "Delete",
                     href: work_package_issue_path(work_package_id: @issue.work_package.id, id: @issue.id),
                     form_arguments: {
                       method: :delete, data: { confirm: "Are you sure?", 'turbo-stream': true }
                     })
    end

    def resolve_action_item(menu)
      return unless @issue.open?

      menu.with_item(label: "Resolve",
                     href: edit_resolution_work_package_issue_path(
                       work_package_id: @issue.work_package.id, id: @issue.id
                     ))
    end

    def reopen_action_item(menu)
      return unless @issue.closed?

      menu.with_item(label: "Reopen",
                     href: reopen_work_package_issue_path(
                       work_package_id: @issue.work_package.id, id: @issue.id
                     ),
                     form_arguments: {
                       method: :patch, data: { confirm: "Are you sure?", 'turbo-stream': true }
                     })
    end

    def add_to_meeting_action_item(menu)
      return unless @issue.open?

      menu.with_item(label: "Add to meeting",
                     href: new_meeting_work_package_issue_path(
                       work_package_id: @issue.work_package.id, id: @issue.id
                     ))
    end

    def count_active_work_package_references_in_meeting
      @meeting.agenda_items.where(work_package_id: @active_work_package.id).count if @active_work_package.present?
    end

    def meeting_assignment_partial(meeting_agenda_item)
      flex_layout do |flex|
        flex.with_column(mr: 1) do
          render(Primer::Beta::Octicon.new(icon: "comment-discussion", 'aria-label': "meeting", color: :muted))
        end
        flex.with_column(flex_layout: true, mr: 1) do |flex|
          flex.with_row do
            render(Primer::Beta::Text.new(font_size: :small, color: :muted)) do
              "In meeting #{meeting_link(meeting_agenda_item.meeting)} from #{meeting_agenda_item.meeting.start_time.strftime('%d.%m.%Y')}".html_safe
            end
          end
          if meeting_agenda_item.details.present?
            flex.with_row(mt: 1, ml: 1, border: :left, pl: 2) do
              render(Primer::Box.new(font_size: :small, color: :default)) do
                simple_format(meeting_agenda_item.details, {}, wrapper_tag: "span")
              end
            end
          end
        end
      end
    end

    def meeting_link(meeting)
      link_to(meeting_path(meeting), target: "_blank", rel: "noopener") do
        meeting.title
      end
    end

    def description_partial
      if @issue.open?
        open_description_partial
      else
        flex_layout do |flex|
          flex.with_row do
            resolution_partial
          end
          flex.with_row(ml: 2, mt: 1, border: :left) do
            historic_description_partial
          end
        end
      end
    end

    def open_description_partial(color = :default)
      render(Primer::Box.new(font_size: :small, color:)) do
        simple_format(@issue.description, {}, wrapper_tag: "span")
      end
    end

    def resolution_partial
      render(Primer::Box.new(font_size: :small)) do
        simple_format(@issue.resolution, {}, wrapper_tag: "span")
      end
    end

    def historic_description_partial
      flex_layout(pl: 2) do |flex|
        flex.with_row do
          original_author_partial
        end
        flex.with_row(mt: 1) do
          open_description_partial
        end
      end
    end

    def original_author_partial
      flex_layout do |flex|
        flex.with_column(mr: 1) do
          render(Primer::Beta::Text.new(font_size: :small, font_style: :italic, color: :muted)) do
            "#{@issue.author.name} created"
          end
        end
        flex.with_column do
          render(Primer::Beta::RelativeTime.new(datetime: @issue.created_at, font_size: :small, font_style: :italic,
                                                color: :muted))
        end
      end
    end
  end
end
