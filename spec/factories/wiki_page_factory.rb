FactoryGirl.define do
  factory :wiki_page do
    wiki
    sequence(:title) { |n| "Wiki Page No. #{n}" }

    factory :wiki_page_with_content do
      after :build do |wiki_page|
        wiki_page.content = FactoryGirl.build :wiki_content, :page => wiki_page
      end
    end
  end
end
