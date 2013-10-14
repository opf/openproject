class Reports::TypeReport < Reports::Report

  def self.report_type
    "type"
  end

  def field
    @field || "type_id"
  end

  def rows
    @rows ||= @project.types
  end

  def data
    @data ||= WorkPackage.by_type(@project)
    end

  def title
    @title = WorkPackage.human_attribute_name(:type)
  end

end

