class DefaultHourlyRate < Rate
  validates_uniqueness_of :valid_from, :scope => :user_id
  validates_presence_of :user_id, :valid_from
  validate :change_of_user_only_on_first_creation
  before_save :convert_valid_from_to_date

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

  def self.at_for_user(date, user_id)
    user_id = user_id.id if user_id.is_a?(User)

    find(:first,
         :conditions => [ "user_id = ? and valid_from <= ?", user_id, date],
         :order => "valid_from DESC")
  end

  private

  def convert_valid_from_to_date
    self.valid_from &&= valid_from.to_date
  end

  def change_of_user_only_on_first_creation
    # Only allow change of user on first creation
    errors.add :user_id, :invalid if !self.new_record? and user_id_changed?
    begin
      valid_from.to_date
    rescue Exception
      errors.add :valid_from, :invalid
    end
  end
end
