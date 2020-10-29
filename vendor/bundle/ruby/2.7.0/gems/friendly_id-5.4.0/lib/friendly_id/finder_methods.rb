module FriendlyId

  module FinderMethods

    # Finds a record using the given id.
    #
    # If the id is "unfriendly", it will call the original find method.
    # If the id is a numeric string like '123' it will first look for a friendly
    # id matching '123' and then fall back to looking for a record with the
    # numeric id '123'.
    #
    # Since FriendlyId 5.0, if the id is a nonnumeric string like '123-foo' it
    # will *only* search by friendly id and not fall back to the regular find
    # method.
    #
    # If you want to search only by the friendly id, use {#find_by_friendly_id}.
    # @raise ActiveRecord::RecordNotFound
    def find(*args)
      id = args.first
      return super if args.count != 1 || id.unfriendly_id?
      first_by_friendly_id(id).tap {|result| return result unless result.nil?}
      return super if potential_primary_key?(id)
      raise_not_found_exception id
      
    end

    # Returns true if a record with the given id exists.
    def exists?(conditions = :none)
      return super if conditions.unfriendly_id?
      return true if exists_by_friendly_id?(conditions)
      super
    end

    # Finds exclusively by the friendly id, completely bypassing original
    # `find`.
    # @raise ActiveRecord::RecordNotFound
    def find_by_friendly_id(id)
      first_by_friendly_id(id) or raise raise_not_found_exception(id)
    end

    def exists_by_friendly_id?(id)
      where(friendly_id_config.query_field => id).exists?
    end

    private

    def potential_primary_key?(id)
      key_type = primary_key_type
      # Hook for "ActiveModel::Type::Integer" instance.
      key_type = key_type.type if key_type.respond_to?(:type)
      case key_type
      when :integer
        Integer(id, 10) rescue false
      when :uuid
        id.match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      else
        true
      end
    end

    def first_by_friendly_id(id)
      find_by(friendly_id_config.query_field => id.downcase)
    end

    def raise_not_found_exception(id)
      message = "can't find record with friendly id: #{id.inspect}"
      if ActiveRecord.version < Gem::Version.create('5.0') then 
        raise ActiveRecord::RecordNotFound.new(message)
      else 
        raise ActiveRecord::RecordNotFound.new(message, name, friendly_id_config.query_field, id)
      end
    end

  end
end
