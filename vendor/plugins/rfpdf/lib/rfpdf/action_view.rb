#-- encoding: UTF-8
module RFPDF
  module ActionView

  private
    def _rfpdf_compile_setup(dsl_setup = false)
      compile_support = RFPDF::TemplateHandler::CompileSupport.new(controller)
      @rfpdf_options = compile_support.options
    end

  end
end

