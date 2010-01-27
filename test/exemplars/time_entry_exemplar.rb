class TimeEntry < ActiveRecord::Base
  generator_for(:spent_on) { Date.today }
  generator_for(:hours) { (rand * 10).round(2) } # 0.01 to 9.99
  generator_for :user, :method => :generate_user

  def self.generate_user
    User.generate_with_protected!
  end
  
end
