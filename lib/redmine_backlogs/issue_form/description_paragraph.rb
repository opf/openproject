class RedmineBacklogs::IssueForm::DescriptionParagraph < ChiliProject::Nissue::IssueView::DescriptionParagraph
  def visible?
    true
  end

  def render(t)
    content_tag(:div,
      content_tag(:p,
        t.text_area_tag("issue[description]", issue.description.to_s,
             :cols => 60,
             :rows => (issue.description.blank? ? 10 : [[10, issue.description.length / 50].max, 100].min),
             :accesskey => t.accesskey(:edit),
             :class => 'wiki-edit')
       ), :id => "issue_descr_fields"
    ) +
    t.wikitoolbar_for('issue_description')
  end
end