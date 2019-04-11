FactoryBot.define do
  factory :my_page, class: Grids::MyPage do
    user
    row_count { 7 }
    column_count { 4 }
    widgets do
      [
        Grids::Widget.new(
          identifier: 'work_packages_assigned',
          start_row: 1,
          end_row: 7,
          start_column: 1,
          end_column: 3
        ),
        Grids::Widget.new(
          identifier: 'work_packages_created',
          start_row: 1,
          end_row: 7,
          start_column: 3,
          end_column: 5
        )
      ]
    end
  end
end
