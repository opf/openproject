class OpenProject::Backlogs::IssueForm < OpenProject::Backlogs::IssueView; end
require_dependency 'open_project/backlogs/work_package_form/custom_field_paragraph'
require_dependency 'open_project/backlogs/work_package_form/description_paragraph'
require_dependency 'open_project/backlogs/work_package_form/fields_paragraph'
require_dependency 'open_project/backlogs/work_package_form/heading'
require_dependency 'open_project/backlogs/work_package_form/notes_paragraph'

class OpenProject::Backlogs::IssueForm < OpenProject::Backlogs::IssueView
 attr_reader :form_id

 def initialize(work_package)
   super(work_package)
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
   @errors_paragraph ||= OpenProject::Nissue::SimpleParagraph.new(@work_package) do |t|
     content_tag(:div, t.error_messages_for('work_package'), :style => "clear:right")
   end
 end

 def heading
   @heading ||= OpenProject::Backlogs::IssueForm::Heading.new(@work_package)
 end

 def notes_paragraph
   @notes_paragraph ||= OpenProject::Backlogs::IssueForm::NotesParagraph.new(@work_package)
 end

 def fields_paragraph
   @fields_paragraph ||= OpenProject::Backlogs::IssueForm::FieldsParagraph.new(@work_package)
 end

 def description_paragraph
   @description_paragraph ||= OpenProject::Backlogs::IssueForm::DescriptionParagraph.new(@work_package)
 end

 def related_work_packages_paragraph
   @related_work_packages_paragraph ||= OpenProject::Nissue::EmptyParagraph.new
 end

 def sub_work_packages_paragraph
   @sub_work_packages_paragraph ||= OpenProject::Nissue::EmptyParagraph.new
 end
end
