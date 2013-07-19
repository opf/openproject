class OpenProject::Nissue::IssueView < OpenProject::Nissue::View
  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def render(t)
    content_tag(:div, [
      title.render(t),
      content_tag(:div, [
        avatar.render(t),
        heading.render(t),
        *render_paragraphs(t)
      ].join.html_safe, :class => @issue.css_classes  + ' details')
    ].join.html_safe, :class => 'issue-view')
  end

  def render_paragraphs(t)
    paragraphs.inject([]) { |m, o| m << o.render(t) << tag(:hr) }[0..-2]
  end

  def paragraphs
    [
      fields_paragraph,
      description_paragraph,
      sub_issues_paragraph,
      related_issues_paragraph
    ].select(&:present?).select(&:visible?)
  end

  def title
    @title ||= OpenProject::Nissue::IssueView::Title.new(@issue)
  end

  def avatar
    @avatar ||= OpenProject::Nissue::IssueView::Avatar.new(@issue)
  end

  def heading
    @heading ||= OpenProject::Nissue::IssueView::Heading.new(@issue)
  end

  def fields_paragraph
    @fields_paragraph ||= OpenProject::Nissue::IssueView::FieldsParagraph.new(@issue)
  end

  def description_paragraph
    @description_paragraph ||= OpenProject::Nissue::IssueView::DescriptionParagraph.new(@issue)
  end

  def sub_issues_paragraph
    @sub_issues_paragraph ||= OpenProject::Nissue::IssueView::SubIssuesParagraph.new(@issue)
  end

  def related_issues_paragraph
    @related_issues_paragraph ||= OpenProject::Nissue::IssueView::RelatedIssuesParagraph.new(@issue)
  end
end
