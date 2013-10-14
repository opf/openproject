class Reports::VersionReport < Reports::Report

  def self.report_type
    "version"
  end

  def field
    @field ||= "fixed_version_id"
  end

  def rows
    @rows ||= @project.shared_versions.sort
  end

  def data
    @data ||= WorkPackage.by_version(@project)
  end

  def title
    @title ||= WorkPackage.human_attribute_name(:version)
  end

end