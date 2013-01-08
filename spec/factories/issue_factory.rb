FactoryGirl.define do
  factory :issue do
    priority
    project
    status :factory => :issue_status
    sequence(:subject) { |n| "Issue No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    author :factory => :user

    after :build do |issue|
      # a valid issue needs a tracker which is known to its project
      issue.tracker = issue.project.trackers.first unless issue.tracker
    end
  end
end
