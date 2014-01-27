
if TaskboardCardConfiguration.find_by_identifier("default").nil?
  TaskboardCardConfiguration.create({identifier: "default",
    name: "Default",
    per_page: 2,
    page_size: "A4",
    orientation: "landscape",
    rows: "rows:\n  row1:\n    has_border: false\n    columns:\n      id:\n        has_label: false\n        font_size: 20\n        font_style: bold\n        priority: 1\n        minimum_lines: 2\n        render_if_empty: false\n        width: 30%\n      due_date:\n        has_label: false\n        font_size: 15\n        font_style: italic\n        priority: 1\n        minimum_lines: 2\n        render_if_empty: false\n        width: 70%\n  row2:\n    has_border: false\n    columns:\n      description:\n        has_label: false\n        font_size: 15\n        font_style: normal\n        priority: 4\n        minimum_lines: 5\n        render_if_empty: false\n        width: 100%\n"})
end