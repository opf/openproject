FactoryGirl.define do
  factory :document do
    project
    category :factory => :document_category
    sequence(:description) { |n| "I am a document's description  No. #{n}" }
    sequence(:title) { |n| "I am the document No. #{n}" }
  end
end
