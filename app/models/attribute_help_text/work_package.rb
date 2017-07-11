class AttributeHelpText::WorkPackage < AttributeHelpText
  def self.available_attributes
    attributes = ::Type.translated_work_package_form_attributes

    # Status and project are currently special attribute that we need to add
    attributes['status'] = WorkPackage.human_attribute_name 'status'
    attributes['project'] = WorkPackage.human_attribute_name 'project'

    attributes
  end

  validates_inclusion_of :attribute_name, in: ->(*) { available_attributes.keys }

  def attribute_scope
    'WorkPackage'
  end

  def type_caption
    I18n.t(:label_work_package)
  end
end
