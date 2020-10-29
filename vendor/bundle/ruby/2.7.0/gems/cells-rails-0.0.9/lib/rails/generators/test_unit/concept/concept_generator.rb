require 'rails/generators/test_unit'

module TestUnit # :nodoc:
  module Generators # :nodoc:
    class ConceptGenerator < Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)
      argument :actions, type: :array, default: []
      check_class_collision suffix: 'ConceptTest'

      def create_test_file
        template 'unit_test.rb.erb', File.join('test/concepts', class_path, file_name, 'cell_test.rb')
      end

      private

      def states
        (['show'] + actions).uniq
      end
    end
  end
end
