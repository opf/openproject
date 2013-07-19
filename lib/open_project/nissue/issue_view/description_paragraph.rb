class OpenProject::Nissue::IssueView::DescriptionParagraph < OpenProject::Nissue::Paragraph
  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def label
    Issue.human_attribute_name(:description)
  end

  def visible?
    @issue.description? or @issue.attachments.any?
  end

  def render(t)
    return unless visible?

    str = StringIO.new

    if @issue.description?
      str << content_tag(:div,
                         t.modal_link_to(l(:button_quote), { :controller => 'issues', :action => 'quoted', :id => @issue },
                                                 :class => 'icon icon-comment quote-link'),
                                                 :class => 'contextual') if t.authorize_for('issue_boxes', 'edit')

      str << content_tag(:p, content_tag(:strong, label))
      str << content_tag(:div, t.textilizable(@issue, :description, :attachments => @issue.attachments), :class => 'wiki')
    end

    str << t.link_to_attachments(@issue)

    str << t.call_hook(:view_issues_show_description_bottom, :issue => @issue)

    str.string
  end
end
