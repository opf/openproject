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
      value = value.to_s if !value.is_a?(String)

      text = ""
      text = text + "#{@property_name}:- " if has_label
      text = text + value

      font_size = Integer(@config['font_size']) # TODO: Not safe!

      # Draw on pdf
      offset = [@orientation[:x_offset], @orientation[:y_offset]]
      box = @pdf.text_box(text,
        {:height => @orientation[:height],
         :width => @orientation[:width],
         :at => offset,
         :size => font_size,
         :padding_bottom => 5,
         :overflow => :truncate})
    end
  end
end