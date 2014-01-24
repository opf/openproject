class InsertDefaultTaskboardCardConfiguration < ActiveRecord::Migration
  def up
    TaskboardCardConfiguration.create!({
      identifier: "DEFAULT",
      name: "Default",
      per_page: 1,
      page_size: "A4",
      rows: "rows:\n  row1:\n    has_border: false\n    columns:\n      id:\n        has_label: false\n        font_size: 20\n        font_style: bold\n        priority: 1\n        minimum_lines: 2\n        render_if_empty: false\n        width: 30%\n      due_date:\n        has_label: false\n        font_size: 15\n        font_style: italic\n        priority: 1\n        minimum_lines: 2\n        render_if_empty: false\n        width: 70%\n  row2:\n    has_border: false\n    columns:\n      description:\n        has_label: false\n        font_size: 15\n        font_style: normal\n        priority: 4\n        minimum_lines: 5\n        render_if_empty: false\n        width: 100%"
    })
  end

  def down
    TaskboardCardConfiguration.delete_all
  end
end
