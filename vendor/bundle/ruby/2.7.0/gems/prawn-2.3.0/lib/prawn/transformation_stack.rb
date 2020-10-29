# frozen_string_literal: true

# transformation_stack.rb : Stores the transformations that have been applied to
# the document
#
# Copyright 2015, Roger Nesbitt. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'matrix'

# rubocop: disable Metrics/ParameterLists, Naming/MethodParameterName
module Prawn
  module TransformationStack
    def add_to_transformation_stack(a, b, c, d, e, f)
      @transformation_stack ||= [[]]
      @transformation_stack.last.push([a, b, c, d, e, f].map(&:to_f))
    end

    def save_transformation_stack
      @transformation_stack ||= [[]]
      @transformation_stack.push(@transformation_stack.last.dup)
    end

    def restore_transformation_stack
      @transformation_stack&.pop
    end

    def current_transformation_matrix_with_translation(x = 0, y = 0)
      transformations = (@transformation_stack || [[]]).last

      matrix = Matrix.identity(3)

      transformations.each do |a, b, c, d, e, f|
        matrix *= Matrix[[a, c, e], [b, d, f], [0, 0, 1]]
      end

      matrix *= Matrix[[1, 0, x], [0, 1, y], [0, 0, 1]]

      matrix.to_a[0..1].transpose.flatten
    end
  end
end
# rubocop: enable Metrics/ParameterLists, Naming/MethodParameterName
