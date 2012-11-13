# Factories

FactoryGirl.define do
  factory :user do
    login
    firstname 'John'
    lastname  'Doe'
    mail { generate(:email) }
  end

  factory :user_preference do
    user
  end

  factory :issue do
    subject 'Issue 1'
    tracker
    project
    author factory: :user
  end

  factory :project do
    name 'Project 1'
    identifier
  end

  factory :tracker do
    name 'Tracker 1'
  end

  factory :token do
    # doesn't need anything
  end

  factory :document do
    title 'Document 1'
    project
    category factory: :document_category
  end

  factory :document_category do
    name 'Document Category 1'
  end

  factory :attachment do
    filename 'some_file.txt'
    container factory: :project
    author factory: :user
  end

  factory :news do
    title 'News 1'
    description 'some news description'
  end

  factory :comment do
    comments 'some comment text'
    commented factory: :news
    author factory: :user
  end

  factory :board do
    name 'Board 1'
    description 'some board description'
    project
  end

  factory :message do
    subject 'Message 1'
    content 'some message content'
    board
  end

  factory :wiki do
    start_page 'home'
    project
  end

  factory :wiki_page do
    title 'wiki page 1'
    wiki
  end

  factory :wiki_content do
    text 'some content'
    page factory: :wiki_page
  end

  factory :version do
    name 'Version 1'
  end
end

# Sequences

FactoryGirl.define do
  sequence :login do |n|
    "foo#{n}"
  end

  sequence :email do |n|
    "foo#{n}@example.com"
  end

  sequence :identifier do |n|
    "identifier-#{n}"
  end
end
