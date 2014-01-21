
FactoryGirl.define do
  factory :taskboard_card_configuration do
    name "Config 1"
    identifier "config1"
    rows "row1"
    per_page 5
    page_size "A4"
    orientation "landscape"
  end

  factory :default_taskboard_card_configuration, :class => TaskboardCardConfiguration do
    name "Default"
    identifier "default"
    rows "row1"
    per_page 5
    page_size "A4"
    orientation "landscape"
  end

  factory :invalid_taskboard_card_configuration, :class => TaskboardCardConfiguration do
    name "Invalid"
    identifier "invalid"
    rows "row1"
    per_page "string"
    page_size "asdf"
    orientation "qwer"
  end
end