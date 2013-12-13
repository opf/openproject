##
# Hack against rabl 0.9.3 which applies config.include_child_root to
# #collection as well as to #child calls as you would expect.
#
module Rabl
  class Engine
    def to_hash_with_hack(options={})
      if is_collection?(@_data_object)
        options[:building_collection] = true
      end
      to_hash_without_hack(options)
    end

    alias_method :to_hash_without_hack, :to_hash
    alias_method :to_hash, :to_hash_with_hack
  end

  class Builder
    def compile_hash_with_hack(options={})
      if options[:building_collection] && !options[:child_root]
        options[:root_name] = false
      end
      compile_hash_without_hack(options)
    end

    alias_method :compile_hash_without_hack, :compile_hash
    alias_method :compile_hash, :compile_hash_with_hack
  end
end
