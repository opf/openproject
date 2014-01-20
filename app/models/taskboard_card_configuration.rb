
class TaskboardCardConfiguration < ActiveRecord::Base
  include OpenProject::PdfExport::Exceptions

  #Note: rows is YAML text which we'll parse into a hash
  attr_accessible :identifier, :name, :rows, :per_page, :page_size, :orientation

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
end