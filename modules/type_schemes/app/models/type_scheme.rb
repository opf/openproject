class TypeScheme < ApplicationRecord
  self.table_name = "type_schemes"

  has_many :items, -> { order(:position) }, class_name: "TypeSchemeItem",
           foreign_key: :scheme_id, inverse_of: :scheme, dependent: :destroy
  has_many :project_assignments, class_name: "ProjectTypeScheme", foreign_key: :scheme_id,
           inverse_of: :scheme, dependent: :restrict_with_error
  has_many :projects, through: :project_assignments

  validates :name, presence: true, uniqueness: true
  validates :is_default, uniqueness: true, if: :is_default
  validate :types_unique
  validate :exactly_one_default_item, if: :active

  scope :active, -> { where(active: true) }

  def types = items.sort_by(&:position).map(&:type)
  def default_item = items.find(&:is_default)
  def default_type = default_item&.type

  private

  def types_unique
    ids = items.reject(&:marked_for_destruction?).map(&:type_id)
    errors.add(:items, :taken) if ids.uniq.size != ids.size
  end

  def exactly_one_default_item
    live = items.reject(&:marked_for_destruction?)
    errors.add(:items, :exactly_one_default) unless live.count(&:is_default) == 1
  end
end
