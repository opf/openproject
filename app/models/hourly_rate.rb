class HourlyRate < Rate
  belongs_to :user
  belongs_to :project
  
  validates_uniqueness_of :valid_from, :scope => [:user_id, :project_id]
  validates_presence_of :user_id, :project_id, :valid_from
  
  def validate
    # Only allow change of project and user on first creation
    return if self.new_record?
    
    errors.add :project_id, :activerecord_error_invalid if project_id_changed?
    errors.add :user_id, :activerecord_error_invalid if user_id_changed?
  end
  
  def previous(reference_date = self.valid_from)
    # This might return a default rate
    self.user.rate_at(reference_date - 1, self.project)
  end
  
  def next(reference_date = self.valid_from)
    HourlyRate.find(
      :first,
      :conditions => [ "user_id = ? and project_id = ? and valid_from > ?",
        self.user_id, self.project_id, reference_date],
      :order => "valid_from ASC"
    )
  end

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
