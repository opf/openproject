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

  factory :dashboard_with_table, class: Grids::Dashboard do
    project
    row_count { 7 }
    column_count { 4 }

    callback(:after_build) do |dashboard|
      query = FactoryBot.create(:query, project: dashboard.project, hidden: true, is_public: true)

      widget = FactoryBot.build(:grid_widget,
                                identifier: 'work_packages_table',
                                start_row: 1,
                                end_row: 7,
                                start_column: 1,
                                end_column: 3,
                                options: {
                                  name: 'Work package table',
                                  queryId: query.id
                                })

      dashboard.widgets = [widget]
    end
  end

  factory :dashboard_with_custom_text, class: Grids::Dashboard do
    project
    row_count { 7 }
    column_count { 4 }

    callback(:after_build) do |dashboard|
      widget = FactoryBot.build(:grid_widget,
                                identifier: 'custom_text',
                                start_row: 1,
                                end_row: 7,
                                start_column: 1,
                                end_column: 3,
                                options: {
                                  name: 'Custom text',
                                  text: 'Lorem ipsum'
                                })

      dashboard.widgets = [widget]
    end
  end
end
