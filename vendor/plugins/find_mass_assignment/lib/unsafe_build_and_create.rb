class ActiveRecord::Base

  # Build and create records unsafely, bypassing attr_accessible.
  # These methods are especially useful in tests and in the console.
  # Inspired in part by http://pastie.textmate.org/104042
  
  class << self
    
    # Make a new record unsafely.
    # This replaces new/build. For example,
    #   User.unsafe_new(:admin => true)
    # works even if 'admin' isn't attr_accessible.
    def unsafe_new(attrs = {})
      record = new
      record.unsafe_attributes = attrs
      record
    end
    
    # Allow an unsafe build.
    # For example,
    #  @blog.posts.unsafe_build(:published => true)
    # works even if 'published' isn't attr_accessible.
    alias_method :unsafe_build, :unsafe_new
    
    # Create a record unsafely.
    # For example,
    #   User.unsafe_create(:admin => true)
    # works even if 'admin' isn't attr_accessible.
    def unsafe_create(attrs)
      record = unsafe_build(attrs)
      record.save
      record
    end
  
    # Same as unsafe_create, but raises an exception on error
    # The analogy to create/create! is exact.
    def unsafe_create!(attrs)
      record = unsafe_build(attrs)
      record.save!
      record
    end
  end

  # Update attributes unsafely.
  # For example,
  #   @user.unsafe_update_attributes(:admin => true)
  # works even if 'admin' isn't attr_accessible.
  def unsafe_update_attributes(attrs)
    self.unsafe_attributes = attrs
    save
  end
  
  # Same as unsafe_update_attributes, but raises an exception on error
  def unsafe_update_attributes!(attrs)
    self.unsafe_attributes = attrs
    save!
  end

  # Set attributes unsafely, bypassing attr_accessible.
  def unsafe_attributes=(attrs)
    raise attr_accessible_error unless attr_accessible_defined?
    attrs.each do |k, v|
      send("#{k}=", v)
    end
  end
  
  private
  
    def attr_accessible_defined?
       !self.class.accessible_attributes.nil?
    end
  
    def attr_accessible_error
      "#{self.class.name} is not protected by attr_accessible"
    end
end