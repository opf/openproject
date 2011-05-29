module Redmine
  module Views
    class ApiTemplateHandler < ActionView::TemplateHandler
      include ActionView::TemplateHandlers::Compilable

      def compile(template) 
        "Redmine::Views::Builders.for(params[:format]) do |api|; #{template.source}; self.output_buffer = api.output; end"
      end
    end
  end
end
