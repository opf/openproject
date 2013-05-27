require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery, :reporting_query_helper => true do
  minimal_query

  before do
    FactoryGirl.create(:admin)
    project = FactoryGirl.create(:project_with_trackers)
    issue = FactoryGirl.create(:issue, project: project)
    FactoryGirl.create(:time_entry, issue: issue, project: project)
  end

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
