module Reporting
  module QueryHelper
    def minimal_query
      before do
        @query = CostQuery.new
        @query.send(:minimal_chain!)
      end
    end
  end
end

Rspec.configure do |c|
  c.extend Reporting::QueryHelper, :reporting_query_helper => true
end
