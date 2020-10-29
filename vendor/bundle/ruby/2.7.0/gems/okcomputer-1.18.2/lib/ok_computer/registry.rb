# Private: Storage of the checks which have been registered with OkComputer.
#
# No one is expected to interact directly with this class, but rather through
# the outer OkComputer interface.
module OkComputer
  class Registry
    # Public: Return the check registered to the given name
    #
    # check_name - The name of the check to retrieve
    #
    # Returns the registered check or raises Registry::CheckNotFound
    def self.fetch(name)
      default_collection.fetch(name)
    rescue KeyError
      raise CheckNotFound, "No matching check"
    end

    # Public: Return an object containing all the registered checks
    #
    # Returns the default_collection CheckCollection instance
    def self.all
      default_collection
    end

    # Private: The list of registered checks, keyed by their unique names
    #
    # Returns a Hash
    singleton_class.send(:alias_method, :registry, :all)

    # Public: The default collection of checks
    #
    # Returns @default_collection
    def self.default_collection
      @default_collection ||= CheckCollection.new('Default Collection')
    end

    # Public: Register the given check with OkComputer
    #
    # check_name - The name of the check to retrieve
    # check_object - Instance of Checker to register
    # collection_name - The name of the check collection the check should be registered to
    def self.register(check_name, check_object, collection_name=nil)
      find_collection(collection_name).register(check_name, check_object)
    end

    # Public: Remove the check of the given name being checked
    #
    # check_name - The name of the check to retrieve
    # collection_name - The name of the check collection the check should be deregistered from
    def self.deregister(check_name, collection_name=nil)
      find_collection(collection_name).deregister(check_name)
    end

    private_class_method def self.find_collection(collection_name=nil)
      collection_name ? default_collection.fetch(collection_name) : default_collection
    rescue KeyError
      raise CollectionNotFound
    end


    # used when fetching a check that has not been registered
    CheckNotFound = Class.new(StandardError)
    CollectionNotFound = Class.new(StandardError)
  end
end
