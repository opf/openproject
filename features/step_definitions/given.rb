Given /^there are multiple export card configurations$/ do
  config1 = ExportCardConfiguration.create!({
    name: "Default",
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "rows:\n    row1:\n      has_border: false\n      columns:\n        id:\n          has_label: false\n          font_size: 15"
  })
  config2 = ExportCardConfiguration.create!({
    name: "Custom",
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "rows:\n    row1:\n      has_border: false\n      columns:\n        id:\n          has_label: false\n          font_size: 15"
  })
  config3 = ExportCardConfiguration.create!({
    name: "Custom 2",
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "rows:\n    row1:\n      has_border: false\n      columns:\n        id:\n          has_label: false\n          font_size: 15"
  })
  [config1, config2]
end