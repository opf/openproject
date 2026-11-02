# frozen_string_literal: true

module TestManagement
  # Milestone list/detail pages and the milestone section of the work package Testing tab.
  # Charts are plain server-rendered SVG (no chart library); every chart has a text
  # equivalent (aria-label + a visible count list).
  module MilestonesHelper
    STATUS_SCHEMES = { "open" => :secondary, "started" => :accent, "completed" => :success }.freeze

    def tm_milestone_status_label(milestone)
      render(Primer::Beta::Label.new(scheme: STATUS_SCHEMES.fetch(milestone.status, :secondary),
                                     data: { test_selector: "tm-milestone-status" })) do
        t("test_management.milestones.statuses.#{milestone.status}")
      end
    end

    def tm_milestone_overdue_badge(milestone)
      return "".html_safe unless milestone.overdue?

      render(Primer::Beta::Label.new(scheme: :danger, data: { test_selector: "tm-milestone-overdue" })) do
        t("test_management.milestones.overdue")
      end
    end

    def tm_milestone_dates(milestone)
      return t("test_management.milestones.no_dates") if milestone.start_date.blank? && milestone.due_date.blank?

      start = milestone.start_date ? format_date(milestone.start_date) : "…"
      due = milestone.due_date ? format_date(milestone.due_date) : "…"
      "#{start} – #{due}"
    end

    def tm_milestone_can_manage?(project)
      User.current.allowed_in_project?(:manage_test_milestones, project)
    end

    # Options for the run form / Run in CI selector: not completed milestones (plus the
    # current one), sub-milestones under their parent.
    def tm_milestone_options_for_select(project, selected: nil)
      options_for_select(tm_milestone_option_pairs(project, selected:), selected)
    end

    def tm_milestone_option_pairs(project, selected: nil)
      milestones = TestManagement::Milestone.where(project_id: project.id).ordered.to_a
      milestones.select! { |m| m.assignable? || m.id == selected.to_i }
      by_parent = milestones.group_by(&:parent_id)
      ids = milestones.to_set(&:id)
      roots = milestones.select { |m| m.parent_id.nil? || ids.exclude?(m.parent_id) }
      roots.flat_map do |root|
        [[root.name, root.id]] + by_parent.fetch(root.id, []).map { |child| ["\u2003↳ #{child.name}", child.id] }
      end
    end

    # "Passed 3 (60%), Failed 1 (20%), …. Pass rate 75%." – used as aria-label and for screen readers.
    def tm_milestone_summary_text(counts)
      total = counts.values.sum
      return t("test_management.milestones.no_results") if total.zero?

      parts = TestRunCase::STATUSES.filter_map do |status|
        count = counts[status].to_i
        next if count.zero?

        "#{t("test_management.runs.statuses.#{status}")} #{count} (#{tm_status_percent(count, total)}%)"
      end
      "#{parts.join(', ')}. #{t('test_management.milestones.pass_rate_text', rate: TestRun.pass_rate(counts))}"
    end

    # Fluid stacked bar: fills the width of its container (works in the narrow split view).
    def tm_milestone_bar(counts, height: 8)
      total = counts.values.sum
      x = 0.0
      segments = TestRunCase::STATUSES.filter_map do |status|
        count = counts[status].to_i
        next if count.zero?

        w = (count.to_f / total) * 100
        rect = tag.rect(x: x.round(3), y: 0, width: w.round(3), height:, fill: TestRunsHelper::STATUS_COLORS[status],
                        data: { status: })
        x += w
        rect
      end
      segments = [tag.rect(x: 0, y: 0, width: 100, height:, fill: TestRunsHelper::STATUS_COLORS["untested"])] if segments.empty?

      content_tag(:svg, safe_join(segments),
                  width: "100%", height:, viewBox: "0 0 100 #{height}", preserveAspectRatio: "none",
                  class: "tm-ms-bar", role: "img", "aria-label": tm_milestone_summary_text(counts),
                  data: { test_selector: "tm-milestone-bar" })
    end

    # Small donut (stroke-dasharray arcs) with the pass rate in the middle. Decorative: the
    # bar's aria-label and the count list carry the same information.
    def tm_milestone_donut(counts, size: 72, stroke: 10)
      total = counts.values.sum
      r = (size - stroke) / 2.0
      c = size / 2.0
      circumference = 2 * Math::PI * r
      offset = 0.0
      arcs = []
      if total.zero?
        arcs << tag.circle(cx: c, cy: c, r:, fill: "none", stroke: TestRunsHelper::STATUS_COLORS["untested"],
                           "stroke-width": stroke)
      else
        TestRunCase::STATUSES.each do |status|
          count = counts[status].to_i
          next if count.zero?

          length = (count.to_f / total) * circumference
          arcs << tag.circle(cx: c, cy: c, r:, fill: "none",
                             stroke: TestRunsHelper::STATUS_COLORS[status], "stroke-width": stroke,
                             "stroke-dasharray": "#{length.round(3)} #{(circumference - length).round(3)}",
                             "stroke-dashoffset": (-offset).round(3),
                             transform: "rotate(-90 #{c} #{c})", data: { status: })
          offset += length
        end
      end
      arcs << tag.text("#{TestRun.pass_rate(counts)}%", x: c, y: c, "text-anchor": "middle",
                                                        "dominant-baseline": "central", class: "tm-ms-donut--label")
      content_tag(:svg, safe_join(arcs), width: size, height: size, viewBox: "0 0 #{size} #{size}",
                                         class: "tm-ms-donut", "aria-hidden": true, focusable: false,
                                         data: { test_selector: "tm-milestone-donut" })
    end

    # Vertical list "● Passed   3   60%" (non-zero statuses; all when there are no results).
    def tm_milestone_count_list(counts)
      total = counts.values.sum
      items = TestRunCase::STATUSES.filter_map do |status|
        count = counts[status].to_i
        next if count.zero? && total.positive?

        content_tag(:li, class: "tm-ms-counts--item", data: { status: }) do
          tm_run_status_label(status) +
            content_tag(:span, count, class: "tm-ms-counts--count") +
            content_tag(:span, "#{tm_status_percent(count, total)}%", class: "tm-ms-counts--pct")
        end
      end
      content_tag(:ul, safe_join(items), class: "tm-ms-counts", data: { test_selector: "tm-milestone-counts" })
    end
  end
end
