
class ExportCardConfiguration < ActiveRecord::Base

  class RowsYamlValidator < ActiveModel::Validator
    REQUIRED_GROUP_KEYS = ["rows"]
    VALID_GROUP_KEYS = ["rows", "has_border"]
    REQUIRED_ROW_KEYS = ["columns"]
    VALID_ROW_KEYS = ["columns", "height", "priority"]
    # TODO: Security Consideration
    # Should we define which model properties are visible and if so how?
    # VALID_MODEL_PROPERTIES = [""]
    REQUIRED_COLUMN_KEYS = []
    VALID_COLUMN_KEYS = ["has_label", "min_font_size", "max_font_size",
      "font_size", "font_style", "text_align", "minimum_lines", "render_if_empty",
      "width", "indented"]

    def assert_required_keys(hash, valid_keys, required_keys)
      hash.assert_valid_keys valid_keys
      pending_keys = required_keys - hash.keys
      raise(ArgumentError, "Required key(s) not present: #{pending_keys.join(", ")}") unless pending_keys.empty?
    end

    def validate(record)
      if record.rows.nil? || !(YAML::load(record.rows)).is_a?(Hash)
        record.errors[:rows] << "YAML is badly formed."
        return false
      end

      begin
        groups = YAML::load(record.rows)
        groups.each do |gk, gv|
          assert_required_keys(gv, VALID_GROUP_KEYS, REQUIRED_GROUP_KEYS)
          if gv.has_key?("rows") && gv["rows"].is_a?(Hash)
            gv["rows"].each do |rk, rv|
              assert_required_keys(rv, VALID_ROW_KEYS, REQUIRED_ROW_KEYS)
              if rv.has_key?("columns") && rv["columns"].is_a?(Hash)
                rv["columns"].each do |ck, cv|
                  assert_required_keys(cv, VALID_COLUMN_KEYS, REQUIRED_COLUMN_KEYS)
                end
              end
            end
          end
        end
      rescue ArgumentError => e
        record.errors[:rows] << "YAML error: #{e.message}"
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