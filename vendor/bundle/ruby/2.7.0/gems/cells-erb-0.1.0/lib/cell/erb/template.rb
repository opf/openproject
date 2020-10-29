require "erbse"

module Cell
  # Erb contains helpers that are messed up in Rails and do escaping.
  module Erb
    def template_options_for(options)
      {
        template_class: ::Cell::Erb::Template,
        suffix:         "erb"
      }
    end

    def capture(*args)
      yield(*args)
    end

    # Below:
    # Rails specific helper fixes. I hate that. I can't tell you how much I hate those helpers,
    # and their blind escaping for every possible string within the application.
    def content_tag(name, content_or_options_with_block=nil, options=nil, escape=false, &block)
      super
    end

    # We do statically set escape=true since attributes are double-quoted strings, so we have
    # to escape (default in Rails).
    def tag_options(options, escape = true)
      super(options, true)
    end

    def form_tag_with_body(html_options, content)
      "#{form_tag_html(html_options)}" << content.to_s << "</form>"
    end

    def form_tag_html(html_options)
      extra_tags = extra_tags_for_form(html_options)
      "#{tag(:form, html_options, true) + extra_tags}"
    end

    def concat(string)
      raise "[Cells-ERB] The #concat helper uses global state and is not supported anymore.
Please change your code to simple `+` String concatenation or tell the gem authors to remove #concat usage."
    end


    # Erbse-Tilt binding. This should be bundled with tilt. # 1.4. OR should be tilt-erbse.
    class Template < Tilt::Template
      def self.engine_initialized?
        defined? ::Erbse::Engine
      end

      def initialize_engine
        require_template_library "erbse"
      end

      def prepare
        @template = ::Erbse::Engine.new # we also have #options here.
      end

      def precompiled_template(locals)
        # puts @template.call(data)
        @template.call(data)
      end
    end
  end
end
