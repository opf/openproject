FactoryGirl.define do
  factory :wiki_menu_item do
    wiki

    sequence(:name) {|n| "Item No. #{n}" }
    sequence(:title) {|n| "Wiki Title #{n}" }
  end
end
