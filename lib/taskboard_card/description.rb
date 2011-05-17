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

          offset = [0, pdf.bounds.height]

          pdf.font_size(20) do
            description = issue.description ? issue.description : ""

            description.split("\n").each do |line|
              r = RedCloth3.new(line)
              line = r.to_html
              line = Description.strip_tags(line)

              height = pdf.height_of(line)
              if offset[1] - height > pdf.font.height
                offset = text_box(pdf,
                                  line,
                                  {:height => height,
                                   :at => offset})
                offset[1] += 10 #unfortunately I havent't found a way to reduce line spacing when placing
                                #the text line by line
              else
                offset = text_box(pdf,
                                  "[...]",
                                  {:height => pdf.font.height,
                                   :at => [0, pdf.font.height]})
                break
              end
            end
          end

          offset
        end
      end

    end
  end
end