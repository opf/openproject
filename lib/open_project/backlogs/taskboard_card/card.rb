module OpenProject::Backlogs::TaskboardCard
  class Card < CardArea
    unloadable

    include Redmine::I18n

    class << self
      def areas
        [OpenProject::Backlogs::TaskboardCard::Header,
         OpenProject::Backlogs::TaskboardCard::TopAttributes,
         OpenProject::Backlogs::TaskboardCard::Description,
         OpenProject::Backlogs::TaskboardCard::BottomAttributes
        ]
      end

      def margin
        20
      end

      def render(pdf, work_package, options)
        render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do
          y_offset = pdf.bounds.height

          Card.areas.each do |card|
            height = pdf.bounds.height * card.pref_size_percent[1]
            card.render(pdf, work_package, {:at => [0, y_offset],
                                     :height => height})
            y_offset -= height + pdf.bounds.height * 0.01
          end
        end
      end
    end
  end
end
