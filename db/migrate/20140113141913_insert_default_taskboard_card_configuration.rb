class InsertDefaultTaskboardCardConfiguration < ActiveRecord::Migration
  def up
    TaskboardCardConfiguration.create!({
      identifier: "DEFAULT",
      name: "Default",
      per_page: 1,
      page_size: "A4",
      rows: "rows:\n    row1:\n      has_border: false\n      columns:\n        id:\n          has_label: false\n          font_size: \"15\""
    })
  end

  def down
    TaskboardCardConfiguration.delete_all
  end
end
