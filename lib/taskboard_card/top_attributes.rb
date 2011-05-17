module TaskboardCard
  class TopAttributes < CardArea
    unloadable
    include Redmine::I18n

    class << self
      def min_size_total
        [500, 100]
      end

      def pref_size_percent
        [1.0, 0.15]
      end

      def margin
        9
      end

      def render(pdf, issue, options)
         render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

           offset = [0, pdf.bounds.height]

           offset = render_empty_line(pdf, 12, offset)
           render_parent_issue(pdf, issue, offset)
           offset = render_sprint(pdf, issue, offset)
           render_subject(pdf, issue, offset)
           render_effort(pdf, issue, offset)
         end
       end

      def render_parent_issue(pdf, issue, offset)
        pdf.font_size(12) do
          parent_name = issue.parent.present? ? "#{issue.parent.tracker.name} ##{issue.parent.id} #{issue.parent.subject}" : ""

          offset = text_box(pdf,
                            parent_name,
                            {:width => pdf.bounds.width,
                             :height => pdf.font.height,
                             :at => offset})
        end

        offset
      end

      def render_sprint(pdf, issue, offset)
        pdf.font_size(12) do
          offset = text_box(pdf,
                            issue.fixed_version.name,
                            {:width => pdf.bounds.width,
                             :height => pdf.font.height,
                             :align => :right,
                             :at => offset})
        end

        offset
      end

      def render_subject(pdf, issue, offset)
        pdf.font_size(20) do

          offset = text_box(pdf,
                            issue.subject,
                            {:width => pdf.bounds.width,
                             :height => pdf.font.height * 2,
                             :at => offset})
        end

        offset
      end

      def render_effort(pdf, issue, offset)
        type = issue.is_task?
        score = (type == :task ? issue.estimated_hours : issue.story_points)
        score ||= '?'
        score = "#{score} #{type == :task ? l(:label_hours) : l(:label_points)}"

        pdf.font_size(20) do
          offset = text_box(pdf,
                            score,
                            {:width => pdf.bounds.width,
                             :height => pdf.font.height,
                             :align => :right,
                             :at => offset})
        end

        offset
      end
    end
  end
end