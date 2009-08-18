require File.dirname(__FILE__) + '/../test_helper'

class BacklogChartDataTest < ActiveSupport::TestCase
  fixtures :versions, :backlogs, :backlog_chart_data

  def test_done_data_length
    backlog = Backlog.find(1)
    backlog.version.effective_date = "2009-08-14 1:05"
    backlog.version.save!
    chart_data = BacklogChartData.fetch(:backlog_id => 1)
    assert_equal BacklogChartData.count(:all, :conditions => "backlog_id=1"), chart_data[:done].length
  end  
  
end
