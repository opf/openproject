
class ExportCardConfiguration < ActiveRecord::Base

  class RowsYamlValidator < ActiveModel::Validator
    # Note: For now this is just checking to see if it's valid YAML
    def validate(record)
      if record.rows.nil? || !(YAML::load(record.rows)).is_a?(Hash)
        record.errors[:rows] << "Rows YAML is badly formed."
      end
    end
  end

  include OpenProject::PdfExport::Exceptions

  validates :name, presence: true
  validates :rows, rows_yaml: true
  validates :per_page, numericality: { only_integer: true }
  validates :page_size, inclusion: { in: %w(A4),
    message: "%{value} is not a valid page size" }, allow_nil: false
  validates :orientation, inclusion: { in: %w(landscape portrait),
    message: "%{value} is not a valid page size" }, allow_nil: true

  scope :active, -> { where(active: true) }

  def activate
    self.update_attributes!({active: true})
  end

  def deactivate
    if !self.is_default?
      self.update_attributes!({active: false})
    else
      false
    end
  end

  def landscape?
    !portrait?
  end

  def portrait?
    orientation == "portrait"
  end

  def rows_hash
    config = YAML::load(rows)
    raise BadlyFormedExportCardConfigurationError.new("Badly formed YAML") if !config.is_a?(Hash)
    config
  end

  def is_default?
    self.name.downcase == "default"
  end

  def can_delete?
    !self.is_default?
  end

  def can_activate?
    !self.active
  end

  def can_deactivate?
    self.active && !is_default?
  end
end