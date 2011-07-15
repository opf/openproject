class RedmineBacklogs::IssueForm < RedmineBacklogs::IssueView
  attr_reader :form_id
  
  def initialize(issue)
    super(issue)
    @form_id = "form_#{ActiveSupport::SecureRandom.hex(10)}"
  end

  def render(t)
    t.content_tag(:form, super(t), :id => form_id)
  end

  def fields_paragraph
    @fields_paragraph ||= RedmineBacklogs::IssueForm::FieldsParagraph.new(@issue)
  end
end
