desc 'Generate chart data for all backlogs'

namespace :redmine do
  namespace :backlogs_plugin do
    task :generate_chart_data => :environment do
      Backlog.find(:all).select{|b| !b.is_main? }.each{|b| BacklogChartData.generate(b)}
    end
  end
end