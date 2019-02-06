FactoryBot.define do
  factory :board_grid, class: Boards::Grid do
    project
    name { 'My board' }
    row_count { 1 }
    column_count { 4 }
  end
end
