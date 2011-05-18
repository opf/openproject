module TaskboardCard
  class Card < CardArea
    unloadable

    include Redmine::I18n

    class << self
      def areas
        [TaskboardCard::Header,
         TaskboardCard::TopAttributes,
         TaskboardCard::Description,
         TaskboardCard::BottomAttributes
        ]
      end

      def margin
        20
      end

      def render(pdf, issue, options)
        render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do
          y_offset = pdf.bounds.height

          Card.areas.each do |card|
            height = pdf.bounds.height * card.pref_size_percent[1]
            card.render(pdf, issue, {:at => [0, y_offset],
                                     :height => height})
            y_offset -= height + pdf.bounds.height * 0.01
          end
        end
      end
    end
  end
end
