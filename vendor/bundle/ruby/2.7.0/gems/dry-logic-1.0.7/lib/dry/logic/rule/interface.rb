# frozen_string_literal: true

module Dry
  module Logic
    class Rule
      class Interface < ::Module
        attr_reader :arity

        attr_reader :curried

        def initialize(arity, curried)
          @arity = arity
          @curried = curried

          if !variable_arity? && curried > arity
            raise ArgumentError, "wrong number of arguments (#{curried} for #{arity})"
          end

          define_constructor if curried?

          if variable_arity?
            define_splat_application
          elsif constant?
            define_constant_application
          else
            define_fixed_application
          end
        end

        def constant?
          arity.zero?
        end

        def variable_arity?
          arity.equal?(-1)
        end

        def curried?
          !curried.zero?
        end

        def unapplied
          if variable_arity?
            -1
          else
            arity - curried
          end
        end

        def name
          if constant?
            "Constant"
          else
            arity_str = variable_arity? ? "VariableArity" : "#{arity}Arity"
            curried_str = curried? ? "#{curried}Curried" : EMPTY_STRING

            "#{arity_str}#{curried_str}"
          end
        end

        def define_constructor
          assignment =
            if curried.equal?(1)
              "@arg0 = @args[0]"
            else
              "#{curried_args.join(", ")} = @args"
            end

          module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def initialize(*)
              super

              #{assignment}
            end
          RUBY
        end

        def define_constant_application
          module_exec do
            def call(*)
              if @predicate[]
                Result::SUCCESS
              else
                Result.new(false, id) { ast }
              end
            end

            def [](*)
              @predicate[]
            end
          end
        end

        def define_splat_application
          application =
            if curried?
              "@predicate[#{curried_args.join(", ")}, *input]"
            else
              "@predicate[*input]"
            end

          module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def call(*input)
              if #{application}
                Result::SUCCESS
              else
                Result.new(false, id) { ast(*input) }
              end
            end

            def [](*input)
              #{application}
            end
          RUBY
        end

        def define_fixed_application
          parameters = unapplied_args.join(", ")
          application = "@predicate[#{(curried_args + unapplied_args).join(", ")}]"

          module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def call(#{parameters})
              if #{application}
                Result::SUCCESS
              else
                Result.new(false, id) { ast(#{parameters}) }
              end
            end

            def [](#{parameters})
              #{application}
            end
          RUBY
        end

        def curried_args
          @curried_args ||= ::Array.new(curried) { |i| "@arg#{i}" }
        end

        def unapplied_args
          @unapplied_args ||= ::Array.new(unapplied) { |i| "input#{i}" }
        end
      end
    end
  end
end
