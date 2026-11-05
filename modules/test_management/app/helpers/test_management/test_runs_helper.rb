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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  module TestRunsHelper
    STATUS_COLORS = {
      "passed" => "#2da44e",
      "failed" => "#cf222e",
      "blocked" => "#57606a",
      "retest" => "#d4a72c",
      "in_progress" => "#0969da",
      "skipped" => "#8250df",
      "untested" => "#d0d7de"
    }.freeze

    STATE_SCHEMES = {
      "new" => :secondary,
      "in_progress" => :accent,
      "completed" => :success,
      "cancelled" => :danger
    }.freeze

    def tm_run_state_label(run, size: :medium)
      render(Primer::Beta::Label.new(scheme: STATE_SCHEMES.fetch(run.state, :secondary),
                                     size:,
                                     data: { test_selector: "tm-run-state" })) do
        t("test_management.runs.states.#{run.state}")
      end
    end

    def tm_run_status_label(status)
      content_tag(:span, class: "tm-run-status tm-run-status--#{status}", data: { test_selector: "tm-run-status" }) do
        content_tag(:svg, tag.circle(cx: 5, cy: 5, r: 5, fill: STATUS_COLORS.fetch(status, "#d0d7de")),
                    width: 10, height: 10, viewBox: "0 0 10 10", class: "tm-run-status--dot", "aria-hidden": true) +
          content_tag(:span, t("test_management.runs.statuses.#{status}"))
      end
    end

    def tm_status_percent(count, total)
      total.to_i.zero? ? 0 : ((count.to_f / total) * 100).round
    end

    def tm_run_source_label(run)
      return "".html_safe unless run.automation?

      render(Primer::Beta::Label.new(scheme: :accent, data: { test_selector: "tm-run-source" })) do
        t("test_management.runs.automation.badge")
      end
    end

    def tm_safe_url(url)
      url = url.to_s.strip
      url if url.match?(%r{\Ahttps?://[^\s]+\z}i)
    end

    def tm_pass_rate(counts)
      TestManagement::TestRun.pass_rate(counts)
    end

    def tm_run_can_manage?(run)
      User.current.allowed_in_project?(:add_test_runs, run.project)
    end

    def tm_run_can_execute?(run)
      run.active? &&
        (User.current.allowed_in_project?(:execute_test_runs, run.project) || tm_run_can_manage?(run))
    end

    def tm_run_progress_bar(counts, width: 160, height: 10) # rubocop:disable Metrics/AbcSize
      total = counts.values.sum
      x = 0.0
      segments = TestRunCase::STATUSES.filter_map do |status|
        count = counts[status].to_i
        next if count.zero?

        w = total.zero? ? 0 : (count.to_f / total) * width
        rect = tag.rect(x: x.round(2), y: 0, width: w.round(2), height:, fill: STATUS_COLORS[status],
                        data: { status: }) do
          tag.title("#{t("test_management.runs.statuses.#{status}")}: #{count}")
        end
        x += w
        rect
      end
      segments = [tag.rect(x: 0, y: 0, width:, height:, fill: STATUS_COLORS["untested"])] if segments.empty?

      content_tag(:svg, safe_join(segments),
                  width:, height:, viewBox: "0 0 #{width} #{height}",
                  class: "tm-run-progress", role: "img",
                  "aria-label": t("test_management.runs.progress_label"),
                  data: { test_selector: "tm-run-progress" })
    end

    def tm_error_first_line(message, length: 160)
      message.to_s.each_line.map(&:strip).find(&:present?).to_s.truncate(length)
    end

    def tm_error_block(message, trace, selector: "tm-error", open: false) # rubocop:disable Metrics/AbcSize
      return "".html_safe if message.blank? && trace.blank?

      parts = []
      if message.present?
        parts << content_tag(:pre, message.to_s, class: "tm-error--message",
                                                 data: { test_selector: "#{selector}-message" })
      end
      if trace.present? && trace.to_s.strip != message.to_s.strip
        parts << content_tag(:details, class: "tm-error--trace", open: open || nil) do
          content_tag(:summary, t("test_management.run_case.stack_trace"), class: "color-fg-muted") +
            content_tag(:pre, trace.to_s, data: { test_selector: "#{selector}-trace" })
        end
      end
      content_tag(:div, safe_join(parts), class: "tm-error", data: { test_selector: selector })
    end

    def tm_subtree_case_ids(suite_id, suites_by_parent, cases_by_suite)
      ids = []
      queue = [suite_id]
      seen = []
      until queue.empty?
        id = queue.shift
        next if seen.include?(id)

        seen << id
        ids.concat(Array(cases_by_suite[id]).map(&:id))
        queue.concat(Array(suites_by_parent[id]).map(&:id))
      end
      ids
    end

    def tm_run_case_tree(run_cases, suites) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      by_suite = run_cases.group_by { |rc| rc.test_case.suite_id }
      children = suites.group_by(&:parent_id)

      build = lambda do |parent_id|
        Array(children[parent_id]).filter_map do |suite|
          kids = build.call(suite.id)
          own = Array(by_suite[suite.id])
          count = own.size + kids.sum { |kid| kid[:count] }
          next if count.zero?

          { suite:, cases: own, children: kids, count: }
        end
      end

      known = suites.map(&:id)
      unfiled = run_cases.select { |rc| rc.test_case.suite_id.nil? || known.exclude?(rc.test_case.suite_id) }
      [build.call(nil), unfiled]
    end
  end
end
