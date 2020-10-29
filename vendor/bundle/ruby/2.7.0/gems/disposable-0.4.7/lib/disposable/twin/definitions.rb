class Disposable::Twin
  class Definition < Declarative::Definitions::Definition
    def getter
      self[:name]
    end

    def setter
      "#{self[:name]}="
    end

    # :private:
    Filter = ->(definitions, options) do
      definitions.collect do |dfn|
        next if options[:exclude]    and options[:exclude].include?(dfn[:name])
        next if options[:scalar]     and dfn[:collection]
        next if options[:collection] and ! dfn[:collection]
        next if options[:twin]       and ! dfn[:nested]
        dfn
      end.compact
    end

    require "delegate"
    class Each < SimpleDelegator
      def each(options={})
        return __getobj__ unless block_given?

        Definition::Filter.(__getobj__, options).each { |dfn| yield dfn }
      end
    end
  end
end
