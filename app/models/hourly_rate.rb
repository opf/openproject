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

  def self.history_for_user(usr, check_permissions = true)
    rates = Hash.new
    Project.has_module(:costs_module).active.visible.each do |project|
      next if (check_permissions && !User.current.allowed_to?(:view_hourly_rates, project, {:for_user => usr}))

      rates[project] = HourlyRate.find(:all,
          :conditions => { :user_id => usr, :project_id => project },
          :order => "#{HourlyRate.table_name}.valid_from desc")
    end
    
    # FIXME: What permissions to apply here?
    rates[nil] = DefaultHourlyRate.find(:all,
      :conditions => { :user_id => usr},
      :order => "#{DefaultHourlyRate.table_name}.valid_from desc")

    rates
  end
end
