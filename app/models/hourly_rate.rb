class HourlyRate < Rate
  validates_uniqueness_of :valid_from, :scope => [:user_id, :project_id]
  validates_presence_of :user_id, :project_id, :valid_from
  validate :change_of_user_only_on_first_creation


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

  def self.at_date_for_user_in_project(date, user_id, project = nil, include_default = true)
    user_id = user_id.id if user_id.is_a?(User)

    unless project.nil?
      rate = find(:first,
                  :conditions => [ "user_id = ? and project_id = ? and valid_from <= ?", user_id, project, date],
                  :order => "valid_from DESC")
      if rate.nil?
        project = Project.find(project) unless project.is_a?(Project)
        rate = find(:first,
                    :conditions => [ "user_id = ? and project_id in (?) and valid_from <= ?", user_id, project.ancestors, date],
                    :include => :project,
                    :order => "projects.lft DESC, valid_from DESC")
      end
    end
    rate ||= DefaultHourlyRate.at_for_user(date, user_id) if include_default
    rate
  end

  private

  def change_of_user_only_on_first_creation
    # Only allow change of project and user on first creation
    return if self.new_record?

    errors.add :project_id, :invalid if project_id_changed?
    errors.add :user_id, :invalid if user_id_changed?
  end
end
