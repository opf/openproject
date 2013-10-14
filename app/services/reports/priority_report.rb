class Reports::PriorityReport < Reports::Report

  def self.report_type
    "priority"
  end

  def field
    "priority_id"
  end

  def rows
    @rows ||=  IssuePriority.all
  end

  def data
    @data ||= WorkPackage.by_priority(@project)
  end

  def title
    @title ||= WorkPackage.human_attribute_name(:priority)
  end
end