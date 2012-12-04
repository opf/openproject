FactoryGirl.define do
  factory :wiki_page do
    wiki
    sequence(:title) { |n| "Wiki Page No. #{n}" }

    factory :wiki_page_with_content do
      content :factory => :wiki_content
    end
  end
end
