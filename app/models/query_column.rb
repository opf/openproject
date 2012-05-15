class QueryColumn
  attr_accessor :name, :sortable, :groupable, :default_order
  include Redmine::I18n

  def initialize(name, options={})
    self.name = name
    self.sortable = options[:sortable]
    self.groupable = options[:groupable] || false
    if groupable == true
      self.groupable = name.to_s
    end
    self.default_order = options[:default_order]
    @caption_key = options[:caption] || "field_#{name}"
  end

  def caption
    l(@caption_key)
  end

  # Returns true if the column is sortable, otherwise false
  def sortable?
    !sortable.nil?
  end

  def value(issue)
    issue.send name
  end
end
