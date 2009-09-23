class DefaultHourlyRate < Rate
  belongs_to :user
  
  validates_uniqueness_of :valid_from, :scope => :user_id
  validates_presence_of :user_id, :valid_from
  
  def validate
    # Only allow change of project and user on first creation
    return if self.new_record?
    
    errors.add :user_id, :activerecord_error_invalid if user_id_changed?
  end

  def next(reference_date = self.valid_from)
    DefaultHourlyRate.find(
      :first,
      :conditions => [ "user_id = ? and valid_from > ?",
        self.user_id, reference_date],
      :order => "valid_from ASC"
    )
  end
  
  def previous(reference_date = self.valid_from)
    self.user.default_rate_at(reference_date - 1)
  end
end
