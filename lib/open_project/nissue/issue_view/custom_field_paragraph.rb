class OpenProject::Nissue::IssueView::CustomFieldParagraph < OpenProject::Nissue::Paragraph
  def initialize(custom_value)
    @custom_value = custom_value
  end

  def label
    @custom_value.custom_field.name
  end

  def render(t)
    t.simple_format_without_paragraph(t.show_value(@custom_value))
  end
end
