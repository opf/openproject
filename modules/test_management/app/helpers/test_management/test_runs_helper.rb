# frozen_string_literal: true

module TestManagement
  module TestRunsHelper
    # Colors used by the status pie chart, progress bars and status dots.
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

    # Pass rate shown in the run list / run page: skipped cases are excluded.
    def tm_run_source_label(run)
      return "".html_safe unless run.automation?

      render(Primer::Beta::Label.new(scheme: :accent, data: { test_selector: "tm-run-source" })) do
        t("test_management.runs.automation.badge")
      end
    end

    # Only http(s) links from CI metadata are rendered as links.
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

    # Horizontal stacked bar (SVG, so no inline styles are needed).
    def tm_run_progress_bar(counts, width: 160, height: 10)
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

    # Server-rendered SVG pie chart with "NN% (count)" slice labels.
    def tm_run_pie_chart(counts, size: 220)
      total = counts.values.sum
      r = size * 0.32
      c = size / 2.0
      parts = []

      if total.zero?
        parts << tag.circle(cx: c, cy: c, r:, fill: STATUS_COLORS["untested"])
      else
        angle = -Math::PI / 2
        TestRunCase::STATUSES.each do |status|
          count = counts[status].to_i
          next if count.zero?

          sweep = (count.to_f / total) * 2 * Math::PI
          parts << tm_pie_slice(c, r, angle, sweep, STATUS_COLORS[status], status, count)
          mid = angle + (sweep / 2)
          label_r = r + (size * 0.11)
          parts << tag.text("#{tm_status_percent(count, total)}% (#{count})",
                            x: (c + (label_r * Math.cos(mid))).round(1),
                            y: (c + (label_r * Math.sin(mid))).round(1),
                            "text-anchor": "middle", "dominant-baseline": "middle",
                            class: "tm-pie--label", data: { status: })
          angle += sweep
        end
      end

      content_tag(:svg, safe_join(parts),
                  width: size, height: size, viewBox: "0 0 #{size} #{size}",
                  class: "tm-pie", role: "img",
                  "aria-label": t("test_management.runs.sections.chart_title"),
                  data: { test_selector: "tm-run-pie" })
    end

    def tm_pie_slice(center, radius, start, sweep, color, status, count)
      title = tag.title("#{t("test_management.runs.statuses.#{status}")}: #{count}")
      if sweep >= (2 * Math::PI) - 0.0001
        return tag.circle(cx: center, cy: center, r: radius, fill: color, data: { status: }) { title }
      end

      x1 = center + (radius * Math.cos(start))
      y1 = center + (radius * Math.sin(start))
      x2 = center + (radius * Math.cos(start + sweep))
      y2 = center + (radius * Math.sin(start + sweep))
      large = sweep > Math::PI ? 1 : 0
      d = format("M%<c>.2f,%<c>.2f L%<x1>.2f,%<y1>.2f A%<r>.2f,%<r>.2f 0 %<large>d,1 %<x2>.2f,%<y2>.2f Z",
                 c: center, x1:, y1:, r: radius, large:, x2:, y2:)
      tag.path(d:, fill: color, stroke: "#fff", "stroke-width": 1, data: { status: }) { title }
    end

    STEP_STATUS_COLORS = {
      "passed" => "#2da44e", "failed" => "#cf222e", "blocked" => "#57606a",
      "skipped" => "#8250df", "untested" => "#d0d7de"
    }.freeze

    # Step result status (0020): "untested" is shown as "Not run".
    def tm_step_status_label(status)
      content_tag(:span, class: "tm-run-status tm-step-status--#{status}", data: { test_selector: "tm-step-status" }) do
        content_tag(:svg, tag.circle(cx: 5, cy: 5, r: 5, fill: STEP_STATUS_COLORS.fetch(status, "#d0d7de")),
                    width: 10, height: 10, viewBox: "0 0 10 10", class: "tm-run-status--dot", "aria-hidden": true) +
          content_tag(:span, t("test_management.step_results.statuses.#{status}", default: status.to_s))
      end
    end

    # First line of an error message (for rows and the Testing tab), plain text.
    def tm_error_first_line(message, length: 160)
      message.to_s.each_line.map(&:strip).find(&:present?).to_s.truncate(length)
    end

    # The printed error of a result or step (0020): the message in a <pre> and the stack trace in a
    # collapsible <details>. Everything is escaped by content_tag; nothing is rendered as HTML.
    def tm_error_block(message, trace, selector: "tm-error", open: false)
      return "".html_safe if message.blank? && trace.blank?

      parts = []
      if message.present?
        parts << content_tag(:pre, message.to_s, class: "tm-error--message",
                                                 data: { test_selector: "#{selector}-message" })
      end
      if trace.present? && trace.to_s.strip != message.to_s.strip
        parts << content_tag(:details, class: "tm-error--trace", open: open || nil) do
          content_tag(:summary, t("test_management.step_results.stack_trace"), class: "color-fg-muted") +
            content_tag(:pre, trace.to_s, data: { test_selector: "#{selector}-trace" })
        end
      end
      content_tag(:div, safe_join(parts), class: "tm-error", data: { test_selector: selector })
    end

    # "Failed at step 3: <first line>" for a result, or the first error line; nil when it passed.
    def tm_result_failure_line(result, length: 160)
      return if result.nil?

      step = result.failed_step
      message = result.error_message.presence || step&.error_message.presence || step&.actual_result
      line = tm_error_first_line(message, length:)
      return line.presence unless step

      text = t("test_management.step_results.failed_at_step", number: step.number)
      line.present? ? "#{text}: #{line}" : text
    end

    # Ids of all cases in a folder and its subfolders (in memory, for the selection tree).
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

    # Groups run cases by folder hierarchy for the run page.
    # Returns [nodes, unfiled_cases]; node = { suite:, cases:, children: [...], count: }
    # Only folders that contain run cases (directly or below) are included.
    def tm_run_case_tree(run_cases, suites)
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
