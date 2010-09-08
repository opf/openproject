require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery do
  minimal_query

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :time_entries
  fixtures :enumerations
  fixtures :issue_statuses
  fixtures :roles
  fixtures :issue_categories
  fixtures :versions

  describe CostQuery::Transformer do
    it "should walk down row_first" do
      @query.group_by :issue_id
      @query.column :tweek
      @query.row :project_id
      @query.row :user_id

      result = @query.transformer.row_first.values.first
      [:user_id, :project_id, :tweek].each do |field|
        result.fields.should include(field)
        result = result.values.first
      end
    end

    it "should walk down column_first" do
      @query.group_by :issue_id
      @query.column :tweek
      @query.row :project_id
      @query.row :user_id

      result = @query.transformer.column_first.values.first
      [:tweek, :issue_id].each do |field|
        result.fields.should include(field)
        result = result.values.first
      end
    end
  end
end