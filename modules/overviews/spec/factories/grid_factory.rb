FactoryBot.define do
  factory :overview, class: Grids::Overview do
    project
    row_count { 7 }
    column_count { 4 }
    widgets do
      []
    end
  end
end
