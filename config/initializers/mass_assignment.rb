class ActiveRecord::Base
  # for full security the following call will disallow any attributes by default
  # attr_accessible

  # call this to force mass assignment even of protected attributes
  def force_attributes=(new_attributes)
    self.send(:attributes=, new_attributes, false)
  end

  # this override will protected the foreign key of certain belongs_to associations by default (see #protected_association?)
  # def self.belongs_to(association_id, options = {})
  #   ret = super
  #   if protected_association? association_id
  #     foreign_key = options[:foreign_key] || "#{association_id}_id"
  #     attr_protected foreign_key
  #   end
  #   ret
  # end

  private

  # this method will be called when there is an attempt to mass assign protected attributes
  # it will log the tampered attributes and the class name to the logfile
  # in development mode it will also throw an exception
  #   unless the protected attributes are active record's defaults because it deals with them nicely (id and type usually)
  def log_protected_attribute_removal(*attributes)
    warning = "WARNING: Can't mass-assign these protected attributes: #{attributes.join(', ')} on class #{self.class.name}"
    logger.debug warning
    if (attributes.flatten - attributes_protected_by_default).any?
      raise Exception.new warning unless Rails.env.production?
    end
  end

  # def protected_association?(association_id)
  #   PROTECTED_ASSOCIATIONS.include? association_id.to_s
  # end
  #
  # PROTECTED_ASSOCIATIONS = %w[project user author]
end
