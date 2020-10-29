# frozen_string_literal: true

require 'dry/core/cache'
require 'dry/types/predicate_registry'

module Dry
  module Types
    # PredicateInferrer returns the list of predicates used by a type.
    #
    # @api public
    class PredicateInferrer
      extend Core::Cache

      TYPE_TO_PREDICATE = {
        DateTime => :date_time?,
        FalseClass => :false?,
        Integer => :int?,
        NilClass => :nil?,
        String => :str?,
        TrueClass => :true?,
        BigDecimal => :decimal?
      }.freeze

      REDUCED_TYPES = {
        [[[:true?], [:false?]]] => %i[bool?]
      }.freeze

      HASH = %i[hash?].freeze

      ARRAY = %i[array?].freeze

      NIL = %i[nil?].freeze

      # Compiler reduces type AST into a list of predicates
      #
      # @api private
      class Compiler
        # @return [PredicateRegistry]
        # @api private
        attr_reader :registry

        # @api private
        def initialize(registry)
          @registry = registry
        end

        # @api private
        def infer_predicate(type)
          [TYPE_TO_PREDICATE.fetch(type) { :"#{type.name.split('::').last.downcase}?" }]
        end

        # @api private
        def visit(node)
          meth, rest = node
          public_send(:"visit_#{meth}", rest)
        end

        # @api private
        def visit_nominal(node)
          type = node[0]
          predicate = infer_predicate(type)

          if registry.key?(predicate[0])
            predicate
          else
            [type?: type]
          end
        end

        # @api private
        def visit_hash(_)
          HASH
        end
        alias_method :visit_schema, :visit_hash

        # @api private
        def visit_array(_)
          ARRAY
        end

        # @api private
        def visit_lax(node)
          visit(node)
        end

        # @api private
        def visit_constructor(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_enum(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_sum(node)
          left_node, right_node, = node
          left = visit(left_node)
          right = visit(right_node)

          if left.eql?(NIL)
            right
          else
            [[left, right]]
          end
        end

        # @api private
        def visit_constrained(node)
          other, rules = node
          predicates = visit(rules)

          if predicates.empty?
            visit(other)
          else
            [*visit(other), *merge_predicates(predicates)]
          end
        end

        # @api private
        def visit_any(_)
          EMPTY_ARRAY
        end

        # @api private
        def visit_and(node)
          left, right = node
          visit(left) + visit(right)
        end

        # @api private
        def visit_predicate(node)
          pred, args = node

          if pred.equal?(:type?)
            EMPTY_ARRAY
          elsif registry.key?(pred)
            *curried, _ = args
            values = curried.map { |_, v| v }

            if values.empty?
              [pred]
            else
              [pred => values[0]]
            end
          else
            EMPTY_ARRAY
          end
        end

        private

        # @api private
        def merge_predicates(nodes)
          preds, merged = nodes.each_with_object([[], {}]) do |predicate, (ps, h)|
            if predicate.is_a?(::Hash)
              h.update(predicate)
            else
              ps << predicate
            end
          end

          merged.empty? ? preds : [*preds, merged]
        end
      end

      # @return [Compiler]
      # @api private
      attr_reader :compiler

      # @api private
      def initialize(registry = PredicateRegistry.new)
        @compiler = Compiler.new(registry)
      end

      # Infer predicate identifier from the provided type
      #
      # @param [Type] type
      # @return [Symbol]
      #
      # @api private
      def [](type)
        self.class.fetch_or_store(type) do
          predicates = compiler.visit(type.to_ast)

          if predicates.is_a?(::Hash)
            predicates
          else
            REDUCED_TYPES[predicates] || predicates
          end
        end
      end
    end
  end
end
