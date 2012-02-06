#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
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
    # Legacy is used to support older Redmine style macros by converting
    # them to Liquid objects (tags, filters) on the fly by doing basic
    # string substitution. This is done before the Liquid processing
    # so the converted macros work like normal
    #
    module Legacy
      # Holds the list of legacy macros
      #
      # @param [Regexp] :match The regex to match on the legacy macro
      # @param [String] :replace The string to replace with. E.g. "%" converts
      #        "{{ }}" to "{% %}"
      # @param [String] :new_name The new name of the Liquid object
      def self.macros
        @macros ||= {}
      end

      # "Runs" legacy macros by doing a gsub of their values to the new Liquid ones
      #
      # @param [String] content The pre-Liquid content
      def self.run_macros(content)
        macros.each do |macro_name, macro|
          next unless macro[:match].present? && macro[:replace].present?
          content = content.gsub(macro[:match]) do |match|
            # Use block form so $1 and $2 are set properly
            args = " '#{$2}'" if $2
            "{#{macro[:replace]} #{macro[:new_name]}#{args} #{macro[:replace]}}"
          end
        end
        content
      end

      # Add support for a legacy macro syntax that was converted to liquid
      #
      # @param [String] name The legacy macro name
      # @param [Symbol] liquid_type The type of Liquid object to use. Supported: :tag
      # @param [optional, String] new_name The new name of the liquid object, used
      #        to rename a macro
      def self.add(name, liquid_type, new_name=nil)
        new_name = name unless new_name.present?
        case liquid_type
        when :tag

          macros[name.to_s] = {
            # Example values the regex matches
            # {{name}}
            # {{ name }}
            # {{ name 'arg' }}
            # {{ name('arg') }}
            :match => Regexp.new(/\{\{(#{name})(?:\(([^\}]*)\))?\}\}/),
            :replace => "%",
            :new_name => new_name
          }
        end
      end
    end

    # FIXME: remove the deprecated syntax for 4.0, provide a way to migrate
    # existing pages to the new syntax.
    #
    # See ChiliProject::Liquid::Tags for the registration of the tags.
    Legacy.add('child_pages', :tag)
    Legacy.add('hello_world', :tag)
    Legacy.add('include', :tag)

    # Transform the old textile TOC tags to syntax suported by liquid
    Legacy.add('toc', :tag)
    Legacy.add('>toc', :tag, "toc_right")
    Legacy.add('<toc', :tag, "toc_left")

  end
end
