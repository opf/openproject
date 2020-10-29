module Rails
  module Generators
    class CellGenerator < NamedBase
      source_root File.expand_path('../templates', __FILE__)

      class_option :parent, type: :string, desc: 'The parent class for the generated cell'
      class_option :e, type: :string, desc: 'The template engine'

      check_class_collision suffix: 'Cell'

      argument :actions, type: :array, default: [], banner: 'action action2'

      def create_cell_file
        template 'cell.rb.erb', File.join('app/cells', class_path, "#{file_name}_cell.rb")
      end

      def create_view_files
        states.each do |state|
          @state = state
          @path = File.join('app/cells', class_path, file_name,  "#{state}.#{template_engine}")
          template "view.#{template_engine}", @path
        end
      end

      hook_for :test_framework

      private

      def parent_class_name
        options[:parent] || 'Cell::ViewModel'
      end

      # The show state is included by default
      def states
        (['show'] + actions).uniq
      end

      def template_engine
        (options[:e] || Rails.application.config.app_generators.rails[:template_engine] || 'erb').to_s
      end
    end
  end
end
