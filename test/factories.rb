FactoryGirl.define do
  sequence :login do |n|
    "foo#{n}"
  end

  sequence :email do |n|
    "foo#{n}@example.com"
  end

  factory :user do
    login
    firstname 'John'
    lastname  'Doe'
    mail { generate(:email) }
  end

  factory :issue do
    subject 'Issue 1'
    tracker
    project
    author factory: :user
  end

  factory :project do
    name 'Project 1'
    identifier 'project-1'
  end
  
  factory :tracker do
    name 'Tracker 1'
  end

  factory :token do
  end
end