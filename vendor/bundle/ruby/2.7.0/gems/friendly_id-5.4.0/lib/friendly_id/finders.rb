module FriendlyId
=begin
## Performing Finds with FriendlyId

FriendlyId offers enhanced finders which will search for your record by
friendly id, and fall back to the numeric id if necessary. This makes it easy
to add FriendlyId to an existing application with minimal code modification.

By default, these methods are available only on the `friendly` scope:

    Restaurant.friendly.find('plaza-diner') #=> works
    Restaurant.friendly.find(23)            #=> also works
    Restaurant.find(23)                     #=> still works
    Restaurant.find('plaza-diner')          #=> will not work

### Restoring FriendlyId 4.0-style finders

Prior to version 5.0, FriendlyId overrode the default finder methods to perform
friendly finds all the time. This required modifying parts of Rails that did
not have a public API, which was harder to maintain and at times caused
compatiblity problems. In 5.0 we decided to change the library's defaults and add
the friendly finder methods only to the `friendly` scope in order to boost
compatiblity. However, you can still opt-in to original functionality very
easily by using the `:finders` addon:

    class Restaurant < ActiveRecord::Base
      extend FriendlyId

      scope :active, -> {where(:active => true)}

      friendly_id :name, :use => [:slugged, :finders]
    end

    Restaurant.friendly.find('plaza-diner') #=> works
    Restaurant.find('plaza-diner')          #=> now also works
    Restaurant.active.find('plaza-diner')   #=> now also works

### Updating your application to use FriendlyId's finders

Unless you've chosen to use the `:finders` addon, be sure to modify the finders
in your controllers to use the `friendly` scope. For example:

    # before
    def set_restaurant
      @restaurant = Restaurant.find(params[:id])
    end

    # after
    def set_restaurant
      @restaurant = Restaurant.friendly.find(params[:id])
    end

#### Active Admin

Unless you use the `:finders` addon, you should modify your admin controllers
for models that use FriendlyId with something similar to the following:

    controller do
      def find_resource
        scoped_collection.friendly.find(params[:id])
      end
    end

=end
  module Finders

    module ClassMethods
      if (ActiveRecord::VERSION::MAJOR == 4) && (ActiveRecord::VERSION::MINOR == 0)
        def relation_delegate_class(klass)
          relation_class_name = :"#{klass.to_s.gsub('::', '_')}_#{self.to_s.gsub('::', '_')}"
          klass.const_get(relation_class_name)
        end
      end
    end

    def self.setup(model_class)
      model_class.instance_eval do
        relation.class.send(:include, friendly_id_config.finder_methods)
        if (ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR == 2) || ActiveRecord::VERSION::MAJOR >= 5
          model_class.send(:extend, friendly_id_config.finder_methods)
        end
      end

      # Support for friendly finds on associations for Rails 4.0.1 and above.
      if ::ActiveRecord.const_defined?('AssociationRelation')
        model_class.extend(ClassMethods)
        association_relation_delegate_class = model_class.relation_delegate_class(::ActiveRecord::AssociationRelation)
        association_relation_delegate_class.send(:include, model_class.friendly_id_config.finder_methods)
      end
    end
  end
end
