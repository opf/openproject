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
  class JobStatusComponent < Primer::Component
    include OpPrimer::ComponentHelpers

    def initialize(job:)
      super()
      @job = job
      @active_job = job.active_job
    end

    # rubocop:disable Metrics/AbcSize
    def call
      render(Primer::Box.new) do
        case @job.status
        when :running
          concat(render(Primer::Beta::Octicon.new(icon: :"kebab-horizontal", color: :muted)))
        when :queued,
          :retried,
          :scheduled
          concat(render(Primer::Beta::Octicon.new(icon: :clock, color: :muted)))
        when :succeeded
          concat(render(Primer::Beta::Octicon.new(icon: :"check-circle-fill", color: :success)))
        when :discarded
          concat(render(Primer::Beta::Octicon.new(icon: :"x-circle-fill", color: :danger)))
        end
        concat(render(Primer::Beta::Text.new(ml: 2)) { @active_job.text })
        if @job.status == :discarded
          concat(render(Primer::OpenProject::CollapsibleSection.new(collapsed: true)) do |section|
            section.with_title { @job.error }

            section.with_collapsible_content do
              Array(@job.executions.order(created_at: :desc).limit(1).pick(:error_backtrace)).each do |backtrace_line|
                concat(render(Primer::Beta::Text.new(tag: :p)) { backtrace_line })
              end
            end
          end)
        end
        if @active_job.respond_to?(:percentage)
          concat(
            render(Primer::Beta::ProgressBar.new(size: :default)) do |component|
              component.with_item(percentage: @job.status == :succeeded ? 100 : @active_job.percentage)
            end
          )
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
