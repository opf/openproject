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
  class Issues::ListComponent < Base::Component
    include OpTurbo::Streamable

    def initialize(work_package:, resolved: false)
      super

      @work_package = work_package
      @resolved = resolved
      @open_issues_count = @work_package.issues.open.count
      @closed_issues_count = @work_package.issues.closed.count
      @issues = if resolved
                  @work_package.issues.closed
                else
                  @work_package.issues.open
                end
    end

    def call
      component_wrapper do
        render(Primer::Beta::BorderBox.new) do |component|
          component.with_header do |header|
            header.with_title(tag: :h2) do
              header_partial
            end
          end
          content_partial(component)
        end
      end
    end

    private

    def show_open_issues?
      !@resolved
    end

    def show_closed_issues?
      @resolved
    end

    def header_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 3) do
          open_link_partial
        end
        flex.with_column do
          closed_link_partial
        end
      end
    end

    def open_link_partial
      render(Primer::Beta::Link.new(href: open_work_package_issues_path(@work_package), scheme: :primary,
                                    muted: show_closed_issues?, underline: false, font_weight: open_link_font_weight)) do
        flex_layout do |flex|
          flex.with_column(mr: 1) do
            render(Primer::Beta::Octicon.new(icon: "issue-opened", 'aria-label': "open issues"))
          end
          flex.with_column do
            "#{@open_issues_count} Open"
          end
        end
      end
    end

    def open_link_font_weight
      show_open_issues? ? :bold : :normal
    end

    def closed_link_partial
      render(Primer::Beta::Link.new(href: closed_work_package_issues_path(@work_package), scheme: :primary,
                                    muted: show_open_issues?, underline: false, font_weight: closed_link_font_weight)) do
        flex_layout do |flex|
          flex.with_column(mr: 1) do
            render(Primer::Beta::Octicon.new(icon: "issue-closed", 'aria-label': "closed issues"))
          end
          flex.with_column do
            "#{@closed_issues_count} Closed"
          end
        end
      end
    end

    def closed_link_font_weight
      show_closed_issues? ? :bold : :normal
    end

    def content_partial(component)
      if @issues.empty?
        component.with_body do
          empty_state_partial
        end
      else
        @issues.each do |issue|
          component.with_row do
            render(WorkPackageTab::Issues::ItemComponent.new(issue:))
          end
        end
      end
    end

    def empty_state_partial
      render Primer::Beta::Blankslate.new do |component|
        if show_open_issues?
          component.with_visual_icon(icon: "issue-opened")
          component.with_heading(tag: :h2).with_content("No open issues found for this work package")
        end
        if show_closed_issues?
          component.with_visual_icon(icon: "issue-closed")
          component.with_heading(tag: :h2).with_content("No closed issues found for this work package")
        end
        component.with_description { "Issues help tracking questions, clarifications and descisions." }
      end
    end
  end
end
