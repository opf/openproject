class CostRate < Rate
  belongs_to :cost_type

  validates_uniqueness_of :valid_from, :scope => :cost_type_id
  validate :change_of_cost_type_only_on_first_creation

  def previous(reference_date = self.valid_from)
    # This might return a default rate
    self.cost_type.rate_at(reference_date - 1)
  end

  def next(reference_date = self.valid_from)
    CostRate.find(
      :first,
      :conditions => [ "cost_type_id = ? and valid_from > ?",
        self.cost_type_id, reference_date],
      :order => "valid_from ASC"
    )
  end

  private

  def change_of_cost_type_only_on_first_creation
    errors.add :cost_type_id, :invalid if cost_type_id_changed? && ! self.new_record?
  end
end
