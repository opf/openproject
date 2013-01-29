FactoryGirl.define do
  factory :issue_relation do
    issue_from :factory => :issue
    issue_to { FactoryGirl.build(:issue, :project => issue_from.project) }
    relation_type 'relates' # "relates", "duplicates", "duplicated", "blocks", "blocked", "precedes", "follows"
    delay nil
  end
end
