class Reports::CategoryReport < Reports::Report

  def self.report_type
    "category"
  end

  def field
    "category_id"
  end

  def rows
    @rows ||= @project.categories
  end

  def data
    @data ||= WorkPackage.by_category(@project)
  end

  def title
    @title ||= WorkPackage.human_attribute_name(:category)
  end
end