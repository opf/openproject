FactoryGirl.define do
  factory :issue do
    priority
    sequence(:subject) { |n| "Issue No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    tracker :factory => :tracker_feature
    author :factory => :user
    
    factory :valid_issue do
      after :build do |issue|
        issue.project = Factory.build(:valid_project)
        issue.tracker = issue.project.trackers.first
      end
    end
  end
end
