module OpenProject
  class ARObjectCache
    def self.within(&block)
      ActiveRecord::Base.extend(::OpenProject::ARObjectCache::ObjectCache) unless ActiveRecord::Base.ancestors.include?(::OpenProject::ARObjectCache::ObjectCache)
      block.call
    end

    module ObjectCache
      def find(*args)
        binding.pry
        super
      end
    end
  end
end
