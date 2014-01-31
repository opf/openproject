Given /^there are multiple export card configurations$/ do
  config1 = ExportCardConfiguration.create!({
    name: "Default",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  config2 = ExportCardConfiguration.create!({
    name: "Custom",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  config3 = ExportCardConfiguration.create!({
    name: "Custom 2",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  config4 = ExportCardConfiguration.create!({
    name: "Custom Inactive",
    active: false,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  [config1, config2, config3, config4]
end

Given /^there is the default export card configuration$/ do
  config1 = ExportCardConfiguration.create!({
    name: "Default",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  [config1]
end

Given /^I fill in valid YAML for export config rows$/ do
  valid_yaml = "groups:\n  rows:\n    row1:\n      columns:\n        id:\n          has_label: false"
  fill_in("export_card_configuration_rows", :with => valid_yaml)
end