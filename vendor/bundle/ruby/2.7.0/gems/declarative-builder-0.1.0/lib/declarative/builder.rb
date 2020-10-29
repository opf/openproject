require "declarative/option"

module Declarative
  module Builder
    def self.included(base)
      base.extend DSL
      base.extend Build
    end

    class Builders < Array
      def call(context, *args)
        each do |block|
          klass = block.(context, *args) and return klass # Declarative::Option#call()
        end

        context
      end

      def <<(proc)
        super Declarative::Option( proc, instance_exec: true ) # lambdas are always instance_exec'ed.
      end
    end

    module DSL
      def builders
        @builders ||= Builders.new
      end

      def builds(proc=nil, &block)
        builders << (proc || block)
      end
    end

    module Build
      # Call this from your class to compute the concrete target class.
      def build!(context, *args)
        builders.(context, *args)
      end
    end
  end
end


# Declarative::Builder(->(options) { options[:current_user] ? Bla : Blubb  })
