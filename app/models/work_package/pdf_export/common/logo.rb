module WorkPackage::PDFExport::Common::Logo
  def logo_image
    image_obj, image_info = pdf.build_image_object(logo_image_filename)
    [image_obj, image_info]
  end

  def logo_image_filename
    image_file = custom_logo_image_filename
    image_file = Rails.root.join("app/assets/images/logo_openproject.png") if image_file.nil?
    image_file
  end

  def custom_logo_image_filename
    return unless CustomStyle.current.present? &&
      CustomStyle.current.export_logo.present? && CustomStyle.current.export_logo.local_file.present?

    image_file = CustomStyle.current.export_logo.local_file.path
    content_type = OpenProject::ContentTypeDetector.new(image_file).detect
    return unless pdf_embeddable?(content_type)

    image_file
  end
end
