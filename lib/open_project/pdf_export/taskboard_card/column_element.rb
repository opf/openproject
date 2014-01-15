module OpenProject::PdfExport::TaskboardCard
  class ColumnElement
    def initialize(pdf, property_name, config, orientation, work_package)
      @pdf = pdf
      @property_name = property_name
      @config = config
      @orientation = orientation
      @work_package = work_package
    end

    def draw
      # Get value from model
      has_label = @config['has_label']

      value = @work_package.send(@property_name) if @work_package.respond_to?(@property_name)
      value = value.to_s

      text = ""
      text = text + "#{@property_name}:- " if has_label
      text = text + value

      # Draw on pdf
      offset = [@orientation[:x_offset], @orientation[:y_offset]]
      box = @pdf.text_box(text,
        {:height => 20,
         :at => offset,
         :size => 20,
         :padding_bottom => 5})
    end
  end
end