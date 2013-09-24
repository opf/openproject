#class OpenProject::Backlogs::IssueForm::DescriptionParagraph < OpenProject::Nissue::IssueView::DescriptionParagraph
#  def visible?
#    true
#  end
#
#  def render(t)
#    html_id = "issue_description_#{SecureRandom.hex(10)}"
#    content_tag(:p, content_tag(:strong, WorkPackage.human_attribute_name(:description))) +
#    content_tag(:div,
#      content_tag(:p,
#        t.text_area_tag("issue[description]", work_package.description.to_s,
#             :cols => 60,
#             :rows => (work_package.description.blank? ? 10 : [[10, work_package.description.length / 50].max, 100].min),
#             :accesskey => t.accesskey(:edit),
#             :class => 'wiki-edit',
#             :id => html_id)
#       ), :id => "issue_descr_fields"
#    ) +
#    t.wikitoolbar_for(html_id)
#  end
#end
