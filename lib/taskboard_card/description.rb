module TaskboardCard
  class Description < CardArea
    unloadable

    class << self
      def min_size_total
        [500, 300]
      end

      def pref_size_percent
        [1.0, 0.5]
      end

      def margin
        9
      end

      def render(pdf, issue, options)
        render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

          offset = [0, pdf.bounds.height]

          pdf.font_size(20) do
            description = issue.description ? issue.description : ""

            offset = text_box(pdf,
                              description,
                              {:width => pdf.bounds.width,
                               :height => pdf.font.height * 3,
                               :at => offset})
          end

          offset
        end
      end

    end
  end
end