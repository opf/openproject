module TaskboardCard
  class BottomAttributes < CardArea
    unloadable

    include Redmine::I18n

    class << self
      def min_size_total
        [500, 200]
      end

      def pref_size_percent
        [1.0, 0.3]
      end

      def margin
        9
      end

      def render(pdf, issue, options)
        render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

          offset = [0, pdf.bounds.height]

          render_assigned_to(pdf, issue, offset)
          offset = render_category(pdf, issue, offset)
          offset = render_empty_line(pdf, 12, offset)
          render_sub_issues(pdf, issue, offset)
        end
      end


      def render_assigned_to(pdf, issue, offset)
        pdf.font_size(12) do
          assigned_to = "#{l(:field_assigned_to)}: #{issue.assigned_to ? issue.assigned_to : "-"}"

          offset = text_box(pdf,
                            assigned_to,
                            {:width => pdf.bounds.width,
                             :height => pdf.font.height,
                             :at => offset})
        end

        offset
      end

      def render_category(pdf, issue, offset)
        pdf.font_size(12) do
          category = "#{l(:field_category)}: #{issue.category ? issue.category : "-"}"

          offset = text_box(pdf,
                            category,
                            {:width => pdf.bounds.width,
                             :height => pdf.font.height * 1,
                             :align => :right,
                             :at => offset})
        end

        offset
      end

      def render_sub_issues(pdf, issue, offset)
        pdf.font_size(12) do
          offset = text_box(pdf,
                            "#{l(:label_subtask_plural)}: #{issue.children.size == 0 ? "-" : ""}",
                            {:height => pdf.font.height,
                             :at => offset})

          issue.children.each_with_index do |child, i|
            subtask_text = "#{child.tracker.name} ##{child.id}: #{child.subject}"
            offset[0] = 10 #indentation

            if offset[1] - pdf.font.height < pdf.font.height && issue.children.size - i != 1
              offset = text_box(pdf,
                                l('backlogs.x_more', :count => issue.children.size - i),
                                :height => pdf.font.height,
                                :at => offset)
              break
            else
              offset = text_box(pdf,
                                "#{child.tracker.name} ##{child.id}: #{child.subject}",
                                {:height => pdf.font.height,
                                 :at => offset})
            end
          end
        end

        offset
      end

    end

  end
end