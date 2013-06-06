module Timelines::TimestampsCompatibility
  def updated_on
    self.updated_at
  end

  def updated_on=(other)
    self.updated_at = other
  end

  def created_on
    self.created_at
  end

  def created_on=(other)
    self.created_at = other
  end
end
