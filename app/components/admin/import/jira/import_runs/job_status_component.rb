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
    include Admin::Import::Jira::ImportRunsHelper

    def initialize(job:)
      super()
      @job = job
      @active_job = job.active_job
    end

    # rubocop:disable Metrics/AbcSize
    def call
      flex_layout(style: "gap: 8px;") do |flex|
        flex.with_row do
          render(Primer::Box.new(display: :flex, align_items: :center, justify_content: :space_between)) do
            concat(render(Primer::Box.new(display: :flex, align_items: :center, style: "gap: 8px;")) do
              concat(render(Primer::Beta::Text.new(font_weight: :bold)) { @active_job.text })
              # concat(render(Primer::Beta::Text.new) { "(36/45)" })
            end)
            concat(render(Primer::Box.new(display: :flex, align_items: :center, style: "gap: 8px;")) do
              concat(render(Primer::Beta::Octicon.new(**job_status_icon(@job.status))))
              concat(
                render(Primer::Beta::ProgressBar.new(size: :default, style: "min-width: 300px;")) do |c|
                  percentage = if @job.status == :succeeded
                                 100
                               elsif @active_job.respond_to?(:percentage)
                                 @active_job.percentage
                               else
                                 0
                               end
                  c.with_item(percentage:)
                end
              )
            end)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
