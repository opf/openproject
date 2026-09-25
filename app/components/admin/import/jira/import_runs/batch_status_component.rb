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
    include Admin::Import::Jira::ImportRunsHelper

    JOB_PRIORITY = Hash.new(999).merge(running: 0, discarded: 1)

    STAGES = [
      {
        number: 1,
        icon: :gear
      },
      {
        number: 2,
        icon: :project
      },
      {
        number: 3,
        icon: :people
      },
      {
        number: 4,
        icon: :"person-add"
      },
      {
        number: 5,
        icon: :tools
      },
      {
        number: 6,
        icon: :"op-include-projects"
      },
      {
        number: 7,
        icon: :versions
      },
      {
        number: 8,
        icon: :"op-work-packages"
      },
      {
        number: 9,
        icon: :paperclip
      }
    ].freeze

    def initialize(batch:)
      super()
      @batch = batch
    end

    # rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
    def call
      return if @batch.blank?

      batch_jobs = @batch._record.jobs.order(:created_at).group_by(&:labels)
      flex_layout(style: "gap: 8px;") do |flex|
        STAGES.each do |stage|
          stage_jobs = batch_jobs[Array("stage_#{stage[:number]}")] || []
          stage_jobs_count = stage_jobs.count
          job_count_by_status = stage_jobs.inject(Hash.new(0)) do |h, e|
            h[e.status] += 1
            h
          end
          stage_in_progress = job_count_by_status[:running] > 0 || job_count_by_status[:queued] > 0
          stage_discarded = job_count_by_status[:discarded] > 0 && job_count_by_status[:running] == 0
          stage_succeeded = job_count_by_status.keys == [:succeeded] && job_count_by_status[:succeeded] > 0
          flex.with_row do
            render(Primer::Beta::BorderBox.new) do |box|
              box.with_header(display: :flex, align_items: :center, justify_content: :space_between) do
                concat(render(Primer::Box.new(display: :flex, align_items: :center, style: "gap: 8px;")) do
                  concat(render(Primer::Beta::Counter.new(count: stage[:number])))
                  concat(render(Primer::Beta::Octicon.new(icon: stage[:icon], color: :muted)))
                  concat(render(Primer::Beta::Text.new(font_weight: :bold)) do
                    I18n.t(:"admin.jira.run.wizard.stages.#{stage[:number]}.title")
                  end)
                  if stage_jobs_count > 0
                    concat(render(Primer::Beta::Text.new(color: :muted, font_size: :small)) do
                      I18n.t(:"admin.jira.run.wizard.parts.jobs", count: stage_jobs_count)
                    end)
                  end
                end)
                concat(render(Primer::Box.new(display: :flex, align_items: :center, style: "gap: 8px;")) do
                  if stage_jobs_count == 0
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(percentage: 0)
                    end)
                  elsif stage_succeeded
                    concat(render(Primer::Beta::Octicon.new(icon: :"check-circle-fill", color: :success)))
                    concat(render(Primer::Beta::Text.new(color: :success)) { "Completed" })
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(percentage: 100)
                    end)
                  elsif stage_in_progress
                    concat(render(Primer::Beta::Spinner.new(size: :small, style: "margin-bottom: -2px; margin-right: 5px")))
                    concat(render(Primer::Beta::Text.new(color: :muted)) do
                      "Progress: #{job_count_by_status[:succeeded]}/#{stage_jobs_count}"
                    end)
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(percentage: job_count_by_status[:succeeded] * 100 / stage_jobs_count)
                    end)
                  elsif stage_discarded
                    concat(render(Primer::Beta::Octicon.new(**job_status_icon(:discarded))))
                    concat(render(Primer::Beta::Text.new(color: :muted)) do
                      "Error: #{job_count_by_status[:succeeded]}/#{stage_jobs_count}"
                    end)
                    concat(render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |bar|
                      bar.with_item(bg: :danger_emphasis, percentage: job_count_by_status[:succeeded] * 100 / stage_jobs_count)
                    end)
                  end
                end)
              end
              if stage_discarded
                stage_jobs.find_all { |job| job.status == :discarded }.each do |job|
                  box.with_row do
                    render(Admin::Import::Jira::ImportRuns::JobStatusComponent.new(job:))
                  end
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
              if stage_in_progress
                sorted_stage_jobs = stage_jobs.sort_by { |job| JOB_PRIORITY[job.status] }
                sorted_stage_jobs.first(4).each do |job|
                  box.with_row do
                    render(Admin::Import::Jira::ImportRuns::JobStatusComponent.new(job:))
                  end
                end
                if stage_jobs_count > 4
                  if stage_jobs_count == 5
                    box.with_row do
                      render(Admin::Import::Jira::ImportRuns::JobStatusComponent.new(job: sorted_stage_jobs[4]))
                    end
                  else
                    box.with_row do
                      render(Primer::Beta::Text.new(color: :muted)) do
                        I18n.t(:"admin.jira.run.wizard.stages.#{stage[:number]}.rest_line_text",
                               projects_number: stage_jobs_count - 4)
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
