
FactoryGirl.define do
  factory :export_card_configuration do
    name "Config 1"
    rows "rows:\n    row1:\n      has_border: false\n      columns:\n        id:\n          has_label: false\n          font_size: \"15\""
    per_page 5
    page_size "A4"
    orientation "landscape"
  end

  factory :default_export_card_configuration, :class => ExportCardConfiguration do
    name "Default"
    rows "rows:\n    row1:\n      has_border: false\n      columns:\n        id:\n          has_label: false\n          font_size: \"15\""
    per_page 5
    page_size "A4"
    orientation "landscape"
  end

  factory :invalid_export_card_configuration, :class => ExportCardConfiguration do
    name "Invalid"
    rows "row1"
    per_page "string"
    page_size "asdf"
    orientation "qwer"
  end
end