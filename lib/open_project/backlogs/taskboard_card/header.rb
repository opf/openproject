module OpenProject::Backlogs::TaskboardCard
  class Header < CardArea
    unloadable

    def self.min_size_total
      [500, 50]
    end

    def self.pref_size_percent
      [1.0, 0.05]
    end

    def self.render(pdf, work_package, options)
      render_bounding_box(pdf, options) do

        offset = [0, pdf.bounds.height]

        work_package_identification = "#{work_package.type.name} ##{work_package.id}"

        box = text_box(pdf,
                       work_package_identification,
                       {:height => 20,
                        :at => offset,
                        :size => 20,
                        :padding_bottom => 5})

        offset[1] -= box.height
        pdf.line offset, [pdf.bounds.width, offset[1]]
      end

    end

  end
end
