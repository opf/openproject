
class TaskboardCardConfiguration < ActiveRecord::Base
  include OpenProject::PdfExport::Exceptions

  #Note: rows is YAML text which we'll parse into a hash
  attr_accessible :identifier, :name, :rows, :per_page, :page_size, :orientation
  validates :identifier, presence: true
  validates :name, presence: true
  validates :rows, presence: true
  validates :per_page, numericality: { only_integer: true }
  validates :page_size, inclusion: { in: %w(A4),
    message: "%{value} is not a valid page size" }, allow_nil: false
  validates :orientation, inclusion: { in: %w(landscape portrait),
    message: "%{value} is not a valid page size" }, allow_nil: false

  def landscape?
    !portrait?
  end

  def portrait?
    orientation == "portrait"
  end

  def rows_hash
    config = YAML::load(rows)
    raise BadlyFormedTaskboardCardConfigurationError.new("Badly formed YAML") if !config.is_a?(Hash)
    config
  end

  def is_default?
    self.identifier == "default"
  end
end