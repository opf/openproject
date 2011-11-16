class Backlogs::IssueForm::NotesParagraph < ChiliProject::Nissue::IssueView::DescriptionParagraph
  def visible?
    true
  end

  def render(t)
    html_id = "issue_notes_#{ActiveSupport::SecureRandom.hex(10)}"
    s = content_tag(:fieldset, [
      content_tag(:legend, l(:field_notes)),
      t.text_area_tag('issue[notes]', '', :cols => 60, :rows => 10, :class => 'wiki-edit', :id => html_id),
      t.wikitoolbar_for(html_id) ]
    )
  end
end
