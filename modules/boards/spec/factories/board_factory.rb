FactoryBot.define do
  factory :board_grid, class: Boards::Grid do
    project
    row_count { 1 }
    column_count { 4 }
  end
end
