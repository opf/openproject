module TaskboardCard
  class TopAttributes < CardArea
    unloadable
    include Redmine::I18n

    class << self
      def min_size_total
        [500, 100]
      end

      def pref_size_percent
        [1.0, 0.1]
      end

      def margin
        9
      end

      def render(pdf, issue, options)
         render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

           sprint_box = render_sprint(pdf, issue, {:at => [0, pdf.bounds.height],
                                                   :align => :right})

           render_parent_issue(pdf, issue, {:at => [0, sprint_box.y],
                                            :width => pdf.bounds.width - sprint_box.width})

           effort_box = render_effort(pdf, issue, {:at => [0, pdf.bounds.height - sprint_box.height],
                                                   :align => :right})

           render_subject(pdf, issue, {:at => [0, effort_box.y],
                                       :width => pdf.bounds.width - effort_box.width})
         end
       end

      def render_parent_issue(pdf, issue, options)
        parent_name = issue.parent.present? ? "#{issue.parent.tracker.name} ##{issue.parent.id}: #{issue.parent.subject}" : ""

        text_box(pdf,
                 parent_name,
                 {:height => 12,
                  :size => 12}.merge(options))
      end

      def render_sprint(pdf, issue, options)
        name = issue.fixed_version ? issue.fixed_version.name : "-"

        text_box(pdf,
                 name,
                 {:height => 12,
                  :size => 12}.merge(options))
      end

      def render_subject(pdf, issue, options)
        text_box(pdf,
                 issue.subject,
                 {:height => 20,
                  :size => 20}.merge(options))
      end

      def render_effort(pdf, issue, options)
        type = issue.is_task?
        score = (type == :task ? issue.estimated_hours : issue.story_points)
        score ||= '-'
        score = "#{score} #{type == :task ? l(:label_hours) : l(:label_points)}"

        text_box(pdf,
                 score,
                 {:height => 20,
                  :size => 20}.merge(options))
      end
    end
  end
end