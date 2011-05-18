module TaskboardCard
  class Description < CardArea
    unloadable

    include Redmine::I18n

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

          y_offset = pdf.bounds.height

          description = issue.description ? issue.description : ""

          description.split("\n").each do |line|

            r = RedCloth3.new(line)
            line = r.to_html
            line = Description.strip_tags(line)
            font_height = 20

            if y_offset - font_height > font_height
              box = text_box(pdf,
                             line,
                             {:height => pdf.height_of(line, :size => font_height),
                              :at => [0, y_offset],
                              :size => font_height})

              y_offset -= box.height
            else
              text_box(pdf,
                       "[...]",
                       {:height => font_height,
                        :at => [0, y_offset],
                        :size => font_height})
              break
            end
          end
        end
      end

    end
  end
end