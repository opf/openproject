
class TaskboardCardConfiguration < ActiveRecord::Base

  class RowsYamlValidator < ActiveModel::Validator
    # Note: For now this is just checking to see if it's valid YAML
    def validate(record)
      if record.rows.nil? || !(YAML::load(record.rows)).is_a?(Hash)
        record.errors[:rows] << "Rows YAML is badly formed."
      end
    end
  end

  include OpenProject::PdfExport::Exceptions

  attr_accessible :identifier, :name, :rows, :per_page, :page_size, :orientation
  validates :identifier, presence: true
  validates :name, presence: true
  validates :rows, rows_yaml: true
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