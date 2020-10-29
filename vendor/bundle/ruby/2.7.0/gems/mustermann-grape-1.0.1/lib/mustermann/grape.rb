# frozen_string_literal: true

require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # Grape style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :grape) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#grape Syntax description in the README
  class Grape < AST::Pattern
    register :grape

    on(nil, '?', ')') { |c| unexpected(c) }

    on('*')  { |_c| scan(/\w+/) ? node(:named_splat, buffer.matched) : node(:splat) }
    on(':')  { |_c| node(:capture, constraint: "[^/\\?#\.]") { scan(/\w+/) } }
    on('\\') { |_c| node(:char, expect(/./)) }
    on('(')  { |_c| node(:optional, node(:group) { read unless scan(')') }) }
    on('|')  { |_c| node(:or) }

    on '{' do |_char|
      type = scan('+') ? :named_splat : :capture
      name = expect(/[\w\.]+/)
      type = :splat if (type == :named_splat) && (name == 'splat')
      expect('}')
      node(type, name)
    end

    suffix '?' do |_char, element|
      node(:optional, element)
    end
  end
end
