class OpenProject::JournalFormatter::Attachment < ::JournalFormatter::Base
  unloadable

  include ApplicationHelper

  def self.default_url_options
    { :only_path => true }
  end

  def render(key, values, no_html = false)
    label, old_value, value = format_details(key.sub("attachments", ""), values)

    unless no_html
      label, old_value, value = *format_html_details(label, old_value, value)

      value = format_html_attachment_detail(key.sub("attachments", ""), value)
    end

    render_binary_detail_text(label, value, old_value)
  end

  private

  def label(key)
    l(:label_attachment)
  end

  def format_html_attachment_detail(key, value)
    if !value.blank? && a = Attachment.find_by_id(key.to_i)
      link_to_attachment(a)
    else
      value if value.present?
    end
  end
end
