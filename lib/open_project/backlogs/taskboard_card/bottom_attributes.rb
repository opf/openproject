module OpenProject::Backlogs::TaskboardCard
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

      def render(pdf, work_package, options)
        render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

          category_box = render_category(pdf, work_package, {:at => [0, pdf.bounds.height],
                                                      :align => :right})

          assigned_to_box = render_assigned_to(pdf, work_package, {:at => [0, category_box.y],
                                                            :width => pdf.bounds.width - category_box.width,
                                                            :padding_bottom => 20})

          render_sub_work_packages(pdf, work_package, {:at => [0, assigned_to_box.y - assigned_to_box.height]})
        end
      end


      def render_assigned_to(pdf, work_package, options)

        assigned_to = "#{WorkPackage.human_attribute_name(:assigned_to)}: #{work_package.assigned_to ? work_package.assigned_to : "-"}"

        text_box(pdf,
                 assigned_to,
                 {:width => pdf.bounds.width,
                  :height => 12,
                  :size => 12}.merge(options))
      end

      def render_category(pdf, work_package, options)

        category = "#{WorkPackage.human_attribute_name(:category)}: #{work_package.category ? work_package.category : "-"}"

        text_box(pdf,
                 category,
                 {:width => pdf.bounds.width,
                  :height => 12}.merge(options))

      end

      def render_sub_work_packages(pdf, work_package, options)
        at = options.delete(:at)
        box = Box.new(at[0], at[1], 0, 0)

        pdf.font_size(12) do
          temp_box = text_box(pdf,
                              "#{l(:label_subtask_plural)}: #{work_package.children.size == 0 ? "-" : ""}",
                              {:height => pdf.font.height,
                               :at => box.at,
                               :paddint_bottom => 6})

          box.height += temp_box.height
          box.width = temp_box.width

          work_package.children.each_with_index do |child, i|

            if box.height + pdf.font.height > pdf.font.height ||  work_package.children.size - i == 1
              temp_box = text_box(pdf,
                                "#{child.type.name} ##{child.id}: #{child.subject}",
                                {:height => pdf.font.height,
                                 :at => [10, at[1] - box.height],
                                 :padding_bottom => 3})
            else
              temp_box = text_box(pdf,
                                l('backlogs.x_more', :count => work_package.children.size - i),
                                :height => pdf.font.height,
                                :at => [10, at[1] - box.height])
              break
            end

            box.height += temp_box.height
          end
        end

        box
      end

    end

  end
end
