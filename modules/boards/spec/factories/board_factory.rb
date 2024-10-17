FactoryBot.define do
  factory :board_grid, class: "Boards::Grid" do
    project
    name { "My board" }
    row_count { 1 }
    column_count { 4 }
  end

  factory :board_grid_with_query, class: "Boards::Grid" do
    project
    sequence(:name) { |n| "Board with query #{n}" }
    row_count { 1 }
    column_count { 4 }

    transient do
      query { nil }
    end

    callback(:after_build) do |board, evaluator| # this is also done after :create
      query = evaluator.query || begin
        build(:public_query, name: "List 1", project: board.project).tap do |q|
          q.sort_criteria = [[:manual_sorting, "asc"]]
          q.add_filter(:manual_sort, "ow", [])
          q.save!
        end
      end

      board.widgets << create(:grid_widget,
                              identifier: "work_package_query",
                              start_row: 1,
                              end_row: 2,
                              start_column: 1,
                              end_column: 1,
                              options: { "queryId" => query.id,
                                         "filters" => [{ "manualSort" => { "operator" => "ow", "values" => [] } }] })
    end
  end

  factory :board_grid_with_queries, class: "Boards::Grid" do
    project
    sequence(:name) { |n| "Board with query #{n}" }
    row_count { 1 }
    column_count { 4 }

    transient do
      num_queries { 2 }
    end

    callback(:after_build) do |board, evaluator| # this is also done after :create
      evaluator.num_queries.times do |i|
        query = build(:public_query, name: "List #{i + 1}", project: board.project).tap do |q|
          q.sort_criteria = [[:manual_sorting, "asc"]]
          q.add_filter(:manual_sort, "ow", [])
          q.save!
        end

        board.widgets << create(:grid_widget,
                                identifier: "work_package_query",
                                start_row: 1,
                                end_row: 2,
                                start_column: 1,
                                end_column: 1,
                                options: { "queryId" => query.id,
                                           "filters" => [{ "manualSort" => { "operator" => "ow", "values" => [] } }] })
      end
    end
  end

  factory :subproject_board, class: "Boards::Grid" do
    project
    name { "My board" }
    row_count { 1 }
    column_count { 4 }

    transient do
      projects_columns { [create(:project)] }
    end

    callback(:after_create) do |board, evaluator| # this is also done after :create
      evaluator.projects_columns.each do |project|
        query = build(:public_query, name: project.name, project: board.project).tap do |q|
          q.sort_criteria = [[:manual_sorting, "asc"]]
          q.add_filter("only_subproject_id", "=", [project.id.to_s])
          q.save!
        end

        filters = [{ "onlySubproject" => { "operator" => "=", "values" => [project.id.to_s] } }]

        board.widgets << create(:grid_widget,
                                identifier: "work_package_query",
                                start_row: 1,
                                end_row: 2,
                                start_column: 1,
                                end_column: 1,
                                options: { "queryId" => query.id,
                                           "filters" => filters })
      end

      board.options = { "type" => "action", "attribute" => "subproject" }
      board.save!
    end
  end

  factory :version_board, class: "Boards::Grid" do
    project
    name { "My version board" }
    row_count { 1 }
    column_count { 4 }

    transient do
      version_columns { [create(:version, project:)] }
    end

    callback(:after_create) do |board, evaluator|
      evaluator.version_columns.each do |version|
        query = build(:public_query, name: version.name, project: board.project).tap do |q|
          q.sort_criteria = [[:manual_sorting, "asc"]]
          q.save!
        end

        filters = [{ "version_id" => { "operator" => "=", "values" => [version.id.to_s] } }]

        board.widgets << create(:grid_widget,
                                identifier: "work_package_query",
                                start_row: 1,
                                end_row: 2,
                                start_column: 1,
                                end_column: 1,
                                options: { "queryId" => query.id,
                                           "filters" => filters })
      end

      board.options = { "type" => "action", "attribute" => "version" }
      board.save!
    end
  end
end
