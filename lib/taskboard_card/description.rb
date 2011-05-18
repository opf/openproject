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
          description = issue.description ? issue.description : ""

          r = RedCloth3.new(description)
          line = r.to_html
          line = Description.strip_tags(line)

          text_box(pdf,
                   line,
                   {:height => pdf.bounds.height,
                    :at => [0, pdf.bounds.height],
                    :size => 20,
                    :padding_bottom => 0})
        end
      end
    end
  end
end