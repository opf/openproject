
class AttributeHelpText < ActiveRecord::Base
  def self.available_types
    subclasses.map { |child| child.name.demodulize }
  end

  def self.used_attributes(scope)
    where(type: scope)
      .select(:attribute_name)
      .distinct
      .pluck(:attribute_name)
  end

  validates_presence_of :help_text
  validates_uniqueness_of :attribute_name, scope: :type

  def attribute_caption
    self.class.available_attributes[attribute_name]
  end

  def attribute_scope
    raise 'not implemented'
  end

  def type_caption
    raise 'not implemented'
  end
end

require_dependency 'attribute_help_text/work_package'
