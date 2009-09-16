class HourlyRate < Rate
  belongs_to :user
  belongs_to :project
  
  def self.history_for_user(usr, for_display = true)
    rates = Hash.new
    usr.projects.each do |project|
      next unless (!for_display ||
                   User.current.allowed_to?(:view_all_rates, project) ||
                   usr == User.current && User.current.allowed_to?(:view_own_rate, project)
                  )

      rates[project] = HourlyRate.find(:all,
          :conditions => { :user_id => usr, :project_id => project },
          :order => "#{HourlyRate.table_name}.valid_from desc")
    end
    
    rates[nil] = DefaultHourlyRate.find(:all,
      :conditions => { :user_id => usr},
      :order => "#{DefaultHourlyRate.table_name}.valid_from desc")

    rates
  end
end
