module OpenProject::Reporting
  module QueryHelper
    def minimal_query
      before do
        @query = CostQuery.new
        @query.send(:minimal_chain!)
      end
    end
  end
end

RSpec.configure do |c|
  c.extend OpenProject::Reporting::QueryHelper, :reporting_query_helper => true
end
