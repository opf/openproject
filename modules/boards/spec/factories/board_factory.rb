FactoryBot.define do
  factory :board_grid, class: Boards::Grid do
    project
    name { 'My board' }
    row_count { 1 }
    column_count { 4 }
  end

  factory :board_grid_with_query, class: Boards::Grid do
    project
    sequence(:name) { |n| "Board with query #{n}" }
    row_count { 1 }
    column_count { 4 }

    transient do
      query { nil }
    end

    callback(:after_build) do |board, evaluator| # this is also done after :create
      query = evaluator.query || begin
        Query.new_default(name: 'List 1', is_public: true, project: board.project).tap do |q|
          q.add_filter(:manual_sort, 'ow', [])
          q.save!
        end
      end

      board.widgets << FactoryBot.create(:grid_widget,
                                         identifier: 'work_package_query',
                                         start_row: 1,
                                         end_row: 2,
                                         start_column: 1,
                                         end_column: 1,
                                         options: { 'query_id' => query.id, "filters"=>[{"manualSort"=>{"operator"=>"ow", "values"=>[]}}]})
    end
  end

  factory :board_grid_with_queries, class: Boards::Grid do
    project
    sequence(:name) { |n| "Board with query #{n}" }
    row_count { 1 }
    column_count { 4 }

    transient do
      num_queries { 2 }
    end

    callback(:after_build) do |board, evaluator| # this is also done after :create
      evaluator.num_queries.times do |i|

        query = Query.new_default(name: "List #{i + 1}", is_public: true, project: board.project).tap do |q|
          q.save!
        end

        board.widgets << FactoryBot.create(:grid_widget,
                                           identifier: 'work_package_query',
                                           start_row: 1,
                                           end_row: 2,
                                           start_column: 1,
                                           end_column: 1,
                                           options: { 'query_id' => query.id, "filters"=>[{"manualSort"=>{"operator"=>"ow", "values"=>[]}}]})
      end
    end
  end
end
