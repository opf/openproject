FactoryBot.define do
  factory :dashboard, class: Grids::Dashboard do
    project
    row_count { 7 }
    column_count { 4 }
    widgets do
      [
        Grids::Widget.new(
          identifier: 'work_packages_table',
          start_row: 1,
          end_row: 7,
          start_column: 1,
          end_column: 3
        )
      ]
    end
  end
end
