module OpenProject::Backlogs::TaskboardCard
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

      def render(pdf, work_package, options)
         render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

           sprint_box = render_sprint(pdf, work_package, {:at => [0, pdf.bounds.height],
                                                   :align => :right})

           render_parent_work_package(pdf, work_package, {:at => [0, sprint_box.y],
                                            :width => pdf.bounds.width - sprint_box.width})

           effort_box = render_effort(pdf, work_package, {:at => [0, pdf.bounds.height - sprint_box.height],
                                                   :align => :right})

           render_subject(pdf, work_package, {:at => [0, effort_box.y],
                                       :width => pdf.bounds.width - effort_box.width})
         end
       end

      def render_parent_work_package(pdf, work_package, options)
        parent_name = work_package.parent.present? ? "#{work_package.parent.type.name} ##{work_package.parent.id}: #{work_package.parent.subject}" : ""

        text_box(pdf,
                 parent_name,
                 {:height => 12,
                  :size => 12}.merge(options))
      end

      def render_sprint(pdf, work_package, options)
        name = work_package.fixed_version ? work_package.fixed_version.name : "-"

        text_box(pdf,
                 name,
                 {:height => 12,
                  :size => 12}.merge(options))
      end

      def render_subject(pdf, work_package, options)
        text_box(pdf,
                 work_package.subject,
                 {:height => 20,
                  :size => 20}.merge(options))
      end

      def render_effort(pdf, work_package, options)
        type = work_package.is_task?
        score = (type == :task ? work_package.estimated_hours : work_package.story_points)
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
