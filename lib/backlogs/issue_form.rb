class Backlogs::IssueForm < Backlogs::IssueView; end
require_dependency 'backlogs/issue_form/custom_field_paragraph'
require_dependency 'backlogs/issue_form/description_paragraph'
require_dependency 'backlogs/issue_form/fields_paragraph'
require_dependency 'backlogs/issue_form/heading'
require_dependency 'backlogs/issue_form/notes_paragraph'

class Backlogs::IssueForm < Backlogs::IssueView
  attr_reader :form_id

  def initialize(issue)
    super(issue)
    @form_id = "form_#{ActiveSupport::SecureRandom.hex(10)}"
  end

  def render(t)
    s = super(t)
    content_tag(:form, [
      errors_paragraph.render(t),
      s,
      notes_paragraph.render(t)
    ], :id => form_id)
  end

  def errors_paragraph
    @errors_paragraph ||= ChiliProject::Nissue::SimpleParagraph.new(@issue) do |t|
      content_tag(:div, [ t.error_messages_for 'issue' ], :style => "clear:right")
    end
  end

  def heading
    @heading ||= Backlogs::IssueForm::Heading.new(@issue)
  end

  def notes_paragraph
    @notes_paragraph ||= Backlogs::IssueForm::NotesParagraph.new(@issue)
  end

  def fields_paragraph
    @fields_paragraph ||= Backlogs::IssueForm::FieldsParagraph.new(@issue)
  end

  def description_paragraph
    @description_paragraph ||= Backlogs::IssueForm::DescriptionParagraph.new(@issue)
  end

  def related_issues_paragraph
    @related_issues_paragraph ||= ChiliProject::Nissue::EmptyParagraph.new
  end

  def sub_issues_paragraph
    @sub_issues_paragraph ||= ChiliProject::Nissue::EmptyParagraph.new
  end
end
