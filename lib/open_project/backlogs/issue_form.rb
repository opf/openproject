class OpenProject::Backlogs::IssueForm < OpenProject::Backlogs::IssueView; end
require_dependency 'open_project/backlogs/issue_form/custom_field_paragraph'
require_dependency 'open_project/backlogs/issue_form/description_paragraph'
require_dependency 'open_project/backlogs/issue_form/fields_paragraph'
require_dependency 'open_project/backlogs/issue_form/heading'
require_dependency 'open_project/backlogs/issue_form/notes_paragraph'

class OpenProject::Backlogs::IssueForm < OpenProject::Backlogs::IssueView
 attr_reader :form_id

 def initialize(issue)
   super(issue)
   @form_id = "form_#{SecureRandom.hex(10)}"
 end

 def render(t)
   s = super(t)
   content_tag(:form, [
     errors_paragraph.render(t),
     s,
     notes_paragraph.render(t)
   ].join.html_safe, :id => form_id)
 end

 def errors_paragraph
   @errors_paragraph ||= OpenProject::Nissue::SimpleParagraph.new(@issue) do |t|
     content_tag(:div, t.error_messages_for('issue'), :style => "clear:right")
   end
 end

 def heading
   @heading ||= OpenProject::Backlogs::IssueForm::Heading.new(@issue)
 end

 def notes_paragraph
   @notes_paragraph ||= OpenProject::Backlogs::IssueForm::NotesParagraph.new(@issue)
 end

 def fields_paragraph
   @fields_paragraph ||= OpenProject::Backlogs::IssueForm::FieldsParagraph.new(@issue)
 end

 def description_paragraph
   @description_paragraph ||= OpenProject::Backlogs::IssueForm::DescriptionParagraph.new(@issue)
 end

 def related_issues_paragraph
   @related_issues_paragraph ||= OpenProject::Nissue::EmptyParagraph.new
 end

 def sub_issues_paragraph
   @sub_issues_paragraph ||= OpenProject::Nissue::EmptyParagraph.new
 end
end
