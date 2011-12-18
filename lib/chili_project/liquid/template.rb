#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module ChiliProject
  module Liquid
    class Template < ::Liquid::Template
      # creates a new <tt>Template</tt> object from liquid source code
      def self.parse(source)
        template = self.new
        template.parse(source)
        template
      end


      def context_from_render_options(*args)
        # This method is pulled out straight from the original
        # Liquid::Template#render
        context = case args.first
        when ::Liquid::Context
          args.shift
        when Hash
          ::Liquid::Context.new([args.shift, assigns], instance_assigns, registers, @rethrow_errors)
        when nil
          ::Liquid::Context.new(assigns, instance_assigns, registers, @rethrow_errors)
        else
          raise ArgumentError, "Expect Hash or Liquid::Context as parameter"
        end

        case args.last
        when Hash
          options = args.pop

          if options[:registers].is_a?(Hash)
            self.registers.merge!(options[:registers])
          end

          if options[:filters]
            context.add_filters(options[:filters])
          end

        when Module
          context.add_filters(args.pop)
        when Array
          context.add_filters(args.pop)
        end
        context
      end

      # Render takes a hash with local variables.
      #
      # if you use the same filters over and over again consider registering them globally
      # with <tt>Template.register_filter</tt>
      #
      # Following options can be passed:
      #
      #  * <tt>filters</tt> : array with local filters
      #  * <tt>registers</tt> : hash with register variables. Those can be accessed from
      #    filters and tags and might be useful to integrate liquid more with its host application
      #
      def render(*args)
        return '' if @root.nil?

        context = context_from_render_options(*args)
        context.registers[:html_results] ||= {}

        # ENTER THE RENDERING STAGE

        # 1. Render the input as Liquid
        #    Some tags might register final HTML output in this stage.
        begin
          # for performance reasons we get a array back here. join will make a string out of it
          result = @root.render(context)
          result.respond_to?(:join) ? result.join : result
        ensure
          @errors = context.errors
        end

        # 2. Perform the Wiki markup transformation (e.g. Textile)
        obj = context.registers[:object]
        attr = context.registers[:attribute]
        result = Redmine::WikiFormatting.to_html(Setting.text_formatting, result, :object => obj, :attribute => attr)

        # 3. Now finally, replace the captured raw HTML bits in the final content
        length = nil
        # replace HTML results until we can find no additional variables
        while length != context.registers[:html_results].length do
          length = context.registers[:html_results].length
          context.registers[:html_results].delete_if do |key, value|
            # We use the block variant to avoid the evaluation of escaped
            # characters in +value+ during substitution.
            result.sub!(key) { |match| value }
          end
        end

        result
      end
    end
  end
end
