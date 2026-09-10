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

module Admin::Import::Jira::ImportRuns
  class BatchStatusComponent < Primer::Component
    include OpPrimer::ComponentHelpers

    STAGES = [
      {
        number: 1,
        title: "Fetch Jira configuration",
        icon: :gear
      },
      {
        number: 2,
        title: "Fetch project issues",
        icon: :project
      },
      {
        number: 3,
        title: "Fetch users and custom fields",
        icon: :people
      },
      {
        number: 4,
        title: "Create users, groups and memberships",
        icon: :"person-add"
      },
      {
        number: 5,
        title: "Create jira member project role",
        icon: :tools
      },
      {
        number: 6,
        title: "Create projects",
        icon: :"op-include-projects"
      },
      {
        number: 7,
        title: "Create work packages",
        icon: :"op-work-packages"
      },
      {
        number: 8,
        title: "Download attachments",
        icon: :paperclip
      }
    ].freeze

    def initialize(batch:)
      super()
      @batch = batch
    end

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def call
      return if @batch.blank?

      batch_jobs = @batch._record.jobs.order(:created_at).group_by(&:labels)
      flex_layout(style: "gap: 8px;") do |flex|
        STAGES.each do |stage|
          stage_jobs = batch_jobs[Array("stage_#{stage[:number]}")] || []
          stage_jobs_count = stage_jobs.count
          flex.with_row do
            render(Primer::Beta::BorderBox.new) do |box|
              box.with_header(display: :flex, align_items: :center, justify_content: :space_between) do
                concat(render(Primer::Box.new(display: :flex, align_items: :center, style: "gap: 8px;")) do
                  concat(render(Primer::Beta::Counter.new(count: stage[:number])))
                  concat(render(Primer::Beta::Octicon.new(icon: stage[:icon], color: :muted)))
                  concat(render(Primer::Beta::Text.new(font_weight: :bold)) { stage[:title] })
                  if stage_jobs_count > 0
                    concat(render(Primer::Beta::Text.new(color: :muted, font_size: :small)) do
                      "#{stage_jobs_count} jobs"
                    end)
                  end
                end)
                concat(render(Primer::Box.new(display: :flex, align_items: :center, style: "gap: 8px;")) do
                  if stage_jobs_count == 0
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(percentage: 0)
                    end)

                  elsif stage_jobs.all? { |j| j.status == :succeeded }
                    concat(render(Primer::Beta::Octicon.new(icon: :"check-circle-fill", color: :success)))
                    concat(render(Primer::Beta::Text.new(color: :success)) { "Completed" })
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(percentage: 100)
                    end)
                  elsif stage_jobs.any? { |j| j.status == :discarded }
                    concat(render(Primer::Beta::Octicon.new(icon: :"x-circle-fill", color: :danger)))
                    concat(render(Primer::Beta::Text.new(color: :muted, mr: 3)) { "Error" })
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(bg: :danger_emphasis, percentage: 50)
                    end)
                  else
                    concat(render(Primer::Beta::Spinner.new(size: :small, style: "margin-bottom: -2px; margin-right: 5px")))
                    concat(render(Primer::Beta::Text.new(color: :muted, mr: 3)) { "In progress" })
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(percentage: 50)
                    end)
                  end
                end)
              end
              stage_jobs.each do |job|
                box.with_row do
                  render(Admin::Import::Jira::ImportRuns::JobStatusComponent.new(job:))
                end
                if job.status == :discarded
                  box.with_row(style: "background-color: #FFEBE9;") do
                    flex_layout(style: "gap: 16px;") do |flex|
                      flex.with_row do
                        concat(render(Primer::Beta::Text.new(color: :danger, font_weight: :bold)) { "Error: " })
                        concat(render(Primer::Beta::Text.new) { job.error.to_s })
                      end

                      full_backtrace = job.executions.order(created_at: :desc).limit(1).pick(:error_backtrace)
                      if full_backtrace.present?
                        app_backtrace = Rails.backtrace_cleaner.clean(full_backtrace)
                        flex.with_row(style: "background-color: #F6F8FA;", p: 3, border: true, border_radius: 2) do
                          render(Primer::Alpha::UnderlinePanels.new(label: "Test navigation")) do |component|
                            component.with_tab(selected: true, id: "tab-1") do |tab|
                              tab.with_text { "Application Trace" }
                              tab.with_panel(p: 3) do
                                flex_layout(style: "gap: 16px;") do |flex|
                                  flex.with_row do
                                    app_backtrace.each_with_index do |item, index|
                                      concat(render(Primer::Box.new(display: :flex, style: "gap: 8px;")) do
                                        render(Primer::Beta::Text.new(font_weight: :semibold)) { "#{index + 1}. " } +
                                          render(Primer::Beta::Text.new) { item }
                                      end)
                                    end
                                  end
                                  flex.with_row do
                                    render(
                                      Primer::Beta::ClipboardCopyButton.new(
                                        id: "clipboard-button1231231",
                                        aria: { label: "Copy backtrace" },
                                        value: app_backtrace.join("\n")
                                      )
                                    )
                                  end
                                end
                              end
                            end
                            component.with_tab(selected: false, id: "tab-2") do |tab|
                              tab.with_text { "Full Trace" }
                              tab.with_panel do
                                flex_layout(style: "gap: 16px;") do |flex|
                                  flex.with_row do
                                    full_backtrace.each_with_index do |item, index|
                                      concat(render(Primer::Box.new(display: :flex, style: "gap: 8px;")) do
                                        render(Primer::Beta::Text.new(font_weight: :semibold)) { "#{index + 1}. " } +
                                          render(Primer::Beta::Text.new) { item }
                                      end)
                                    end
                                  end
                                  flex.with_row do
                                    render(
                                      Primer::Beta::ClipboardCopyButton.new(
                                        id: "clipboard-button1231231",
                                        aria: { label: "Copy backtrace" },
                                        value: full_backtrace.join("\n")
                                      )
                                    )
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity
  end
end
