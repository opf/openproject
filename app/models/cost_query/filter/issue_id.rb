class CostQuery::Filter::IssueId < CostQuery::Filter::Base
  label :field_issue

  def self.available_values(*)
    issues = Project.visible.collect { |p| p.issues }.flatten.uniq.sort_by { |i| i.id }
    issues.map { |i| [text_for_issue(i), i.id] }
  end

  def self.heavy?
    true
  end
  not_selectable! if heavy?

  def self.text_for_issue(i)
    i = i.first if i.is_a? Array
    str = "##{i.id} "
    str << (i.subject.length > 30 ? i.subject.first(26)+'...': i.subject)
  end

  def self.text_for_id(i)
    text_for_issue Issue.find(i)
  rescue ActiveRecord::RecordNotFound
    ""
  end
end
