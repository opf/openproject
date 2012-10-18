class ActiveRecord::Base
  # call this to force mass assignment even of protected attributes
  def force_attributes=(new_attributes)
    self.send(:assign_attributes, new_attributes, :without_protection => true)
  end
end
