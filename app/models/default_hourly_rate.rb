class DefaultHourlyRate < Rate
  belongs_to :user

  validates_uniqueness_of :valid_from, :scope => :user_id
  validates_presence_of :user_id, :valid_from

  def validate
    # Only allow change of user on first creation
    errors.add :user_id, :activerecord_error_invalid if !self.new_record? and user_id_changed?
    begin
      valid_from.to_date
    rescue Exception
      errors.add :valid_from, :activerecord_error_invalid
    end
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

  def before_save
    self.valid_from &&= valid_from.to_date
  end
end
