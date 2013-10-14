class Reports::AssigneeReport < Reports::Report

  def self.report_type
    "assigned_to"
  end

  def field
    @field ||= "assigned_to_id"
  end

  def rows
    @rows ||= @project.members.collect { |m| m.user }.sort
  end

  def data
    @data ||= WorkPackage.by_assigned_to(@project)
  end

  def title
    @title ||= WorkPackage.human_attribute_name(:assigned_to)
  end

end