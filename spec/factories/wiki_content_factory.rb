FactoryGirl.define do
  factory :wiki_content do
    page :factory => :wiki_page
    author :factory => :user

    text { |a| "h1. #{a.page.title}\n\nPage Content Version #{a.version}." }
  end
end

