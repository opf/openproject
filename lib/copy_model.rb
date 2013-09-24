require 'tree'


module CopyModel
  module InstanceMethods

    # Copies all attributes from +from_model+
    # except those specified in self.class#not_to_copy.
    # Does NOT save self.
    def copy_attributes(from_model)
      with_model(from_model) do |model|
        # clear unique attributes
        self.safe_attributes = model.attributes.dup.except(*self.class.not_to_copy)
        return self
      end
    end

    # Copies the instance's associations based on the +from_model+.
    # The associations CAN be copied when the instance responds to 
    # something called 'copy_association_name'.
    #
    # For example: If we have a method called #copy_work_packages,
    #              the WorkPackages from the work_packages association can be copied.
    #
    # Accepts an +options+ argument to specify what to copy
    #
    # Examples:
    #   model.copy_associations(1)                                    # => copies everything
    #   model.copy_associations(1, :only => 'members')                # => copies members only
    #   model.copy_associations(1, :only => ['members', 'versions'])  # => copies members and versions
    def copy_associations(from_model, options={})
      to_be_copied = self.class.reflect_on_all_associations.map(&:name)
      to_be_copied = options[:only].to_a unless options[:only].nil?
      to_be_copied = to_be_copied.map(&:to_sym)

      with_model(from_model) do |model|
        self.class.transaction do

          to_be_copied.each do |name|
            if (self.respond_to?(:"copy_#{name}") || self.private_methods.include?(:"copy_#{name}"))
              self.send(:"copy_#{name}", model)
            end
          end
          self
        end
      end
    end

    # copies everything (associations and attributes) based on
    # +from_model+ and saves the instance.
    def copy(from_model, options = {})
      self.save if (self.copy_attributes(from_model) && self.copy_associations(from_model, options))
    end

    # resolves +model+ and returns it,
    # or yields it if a block was passed
    def with_model(model)
      model = model.is_a?(self.class) ? model : self.class.find(model)
      if model
        if block_given?
          yield model
        else
          return model
        end
      else
        nil
      end
    end
  end

  module ClassMethods

    # Overwrite or set CLASS::NOT_TO_COPY to specify
    # which attributes are not safe to copy.
    def not_to_copy
      begin
        self::NOT_TO_COPY
      rescue NameError
        []
      end
    end

    # Copies +from_model+ and returns the new instance.  This will not save
    # the copy
    def copy_attributes(from_model)
      return self.new.copy_attributes(from_model)
    end

    # Creates a new instance and
    # copies everything (associations and attributes) based on
    # +from_model+.
    def copy(from_model, options = {})
      self.new.copy(from_model)
    end
  end

  def self.included(base)
    base.send :include, self::InstanceMethods
    base.send :extend,  self::ClassMethods
  end

  def self.extended(base)
    base.send :include, self::InstanceMethods
    base.send :extend,  self::ClassMethods
  end
end