class TimeEntry < ActiveRecord::Base
  generator_for(:spent_on) { Date.today }
  generator_for(:hours) { (rand * 10).round(2) } # 0.01 to 9.99

end
