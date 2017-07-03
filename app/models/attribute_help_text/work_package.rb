class AttributeHelpText::WorkPackage < AttributeHelpText
  def self.available_attributes
    Hash[::Query.new.available_columns.map { |c| [c.name.to_s, c.caption] }]
  end

  validates_inclusion_of :attribute_name, in: available_attributes.keys

  def attribute_scope
    'WorkPackage'
  end

  def type_caption
    I18n.t(:label_work_package)
  end
end
