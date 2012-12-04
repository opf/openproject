FactoryGirl.define do
  factory :wiki_redirect do
    wiki

    title        'Source'
    redirects_to 'Target'
  end
end
