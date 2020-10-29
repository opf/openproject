require 'rails/generators/test_unit'

module TestUnit # :nodoc:
  module Generators # :nodoc:
    class CellGenerator < Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)
      argument :actions, type: :array, default: []
      check_class_collision suffix: 'CellTest'

      def create_test_file
        template 'unit_test.rb.erb', File.join('test/cells', class_path, "#{file_name}_cell_test.rb")
      end

      private

      def states
        (['show'] + actions).uniq
      end
    end
  end
end
