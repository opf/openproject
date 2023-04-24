module WorkPackage::PDFExport::Page
  def configure_page_size!(layout)
    pdf.options[:page_size] = 'EXECUTIVE' # TODO: 'A4'?
    pdf.options[:page_layout] = layout
    pdf.options[:top_margin] = page_top_margin
    pdf.options[:bottom_margin] = page_bottom_margin
  end

  def write_logo!
    image_obj, image_info, scale = logo_pdf_image
    pdf.repeat :all do
      top = pdf.bounds.top + page_header_top + (logo_height / 2)
      pdf.embed_image image_obj, image_info, { at: [0, top], scale: }
    end
  end

  def logo_pdf_image
    image_file = custom_logo_image
    image_file = Rails.root.join("app/assets/images/logo_openproject.png") if image_file.nil?
    image_obj, image_info = pdf.build_image_object(image_file)
    scale = [logo_height / image_info.height.to_f, 1].min
    [image_obj, image_info, scale]
  end

  def custom_logo_image
    return unless CustomStyle.current.present? &&
      CustomStyle.current.logo.present? && CustomStyle.current.logo.local_file.present?

    image_file = CustomStyle.current.logo.local_file.path
    content_type = OpenProject::ContentTypeDetector.new(image_file).detect
    return unless pdf_embeddable?(content_type)

    image_file
  end

  def write_title!
    pdf.title = heading
    pdf.formatted_text([page_heading_style.merge({ text: heading })])
  end

  def write_headers!
    write_logo!
    write_header_user!(User.current) unless User.current.nil?
  end

  def write_header_user!(user)
    draw_repeating_text("#{user.firstname} #{user.lastname}",
                        :right, pdf.bounds.top + logo_height, page_header_style)
  end

  def write_footers!
    write_footer_date!
    write_footer_page_nr!
    write_footer_title!
  end

  def write_footer_page_nr!
    draw_repeating_dynamic_text(:center, -page_footer_top, page_footer_style) do
      current_page_nr.to_s + total_page_nr_text
    end
  end

  def total_page_nr_text
    @total_page_nr ? "/#{@total_page_nr}" : ''
  end

  def write_footer_title!
    draw_repeating_text(heading, :right, -page_footer_top, page_footer_style)
  end

  def write_footer_date!
    draw_repeating_text(format_date(Time.zone.today), :left, -page_footer_top, page_footer_style)
  end

  def page_header_top
    20
  end

  def page_bottom_margin
    60
  end

  def page_footer_top
    30
  end

  def logo_height
    20
  end

  def page_top_margin
    60
  end

  def page_heading_style
    { size: 14, styles: [:bold] }
  end

  def page_header_style
    { size: 8, style: :normal }
  end

  def page_footer_style
    { size: 8, style: :normal }
  end
end
