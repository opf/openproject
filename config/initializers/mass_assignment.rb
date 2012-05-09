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
  # def protected_association?(association_id)
  #   PROTECTED_ASSOCIATIONS.include? association_id.to_s
  # end
  #
  # PROTECTED_ASSOCIATIONS = %w[project user author]
end
