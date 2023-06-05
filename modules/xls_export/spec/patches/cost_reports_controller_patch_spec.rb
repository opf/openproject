require 'spec_helper'

RSpec.describe 'CostReportsController', "rendering to xls" do
  skip 'XlsExport: CostReports support not yet migrated to Rails 3'

  it "responds with the xls if requested in the index" do
    skip
    render action: :index
    expect(response).to be_redirect
  end

  it "does not respond with the xls if requested in a detail view" do
    skip
    render action: :show
    expect(response).to be_redirect
  end

  it "generates xls from issues" do
    skip
  end
end
