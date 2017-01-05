#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting::Internal::Transformers
  require 'open_project/text_formatting/internal/transformers/text_transformer.rb'

  class MacroTransformer < TextTransformer
    require 'open_project/text_formatting/macros/macro_error_descriptor'
    require 'open_project/text_formatting/macros/unknown_macro_error_descriptor'
    require 'open_project/text_formatting/macros/content_expected_error'
    require 'open_project/text_formatting/macros/internal/macro_registry'

    # make the text nokogiri safe, i.e. make sure that no arbitrary < hit nokogiri
    # or even (html) markup passed to legacy user macros as parameters
    def legacy_pre_process(text, **_options)
      @macros = []
      transform_legacy_toc text
      transform_legacy_macros text
      transform_boolean_attributes text
      text
    end

    # pre both process legacy macro syntax and new macro syntax and replace
    # all occurrences by place holders which we will then replace during
    # either the process or post_process stage
    def pre_process(fragment, **_options)
      fragment.xpath('*').each do |node|
        # we will leave all elements that are not macros intact as
        # they will be filtered by RedmineWikiTransformer
        if OpenProject::TextFormatting::Macros::Internal::MacroRegistry
             .instance.registered?(node.name)
          transform_macro_node node
        end
      end
      fragment
    end

    # process all macros that are executed during the process stage
    def process(fragment, **options)
      process_macros(fragment, options) unless @macros.empty?
      fragment
    end

    # process all macros that are executed during the post_process stage
    def post_process(fragment, **options)
      process_macros(fragment, options, post_process: true) unless @macros.empty?
      fragment
    end

    private

    SUBST_MACRO_RE = /
                     ([{][{]opf:macro:(\d+)[}][}])
                     /x unless const_defined?(:SUBST_MACRO_RE)

    def process_macros(fragment, options, post_process: false)
      fragment.xpath('text()|*//text()').each do |node|
        text = node.text.gsub(SUBST_MACRO_RE) do |_m|
          substitute = $1
          index = $2.to_i
          declared_macro = @macros[index]

          # process escaped macros first, regardless of whether they are post_process
          if declared_macro[:escape]
            process_escaped_macro declared_macro
          else
            do_process_macro fragment, substitute, declared_macro, options, post_process
          end
        end
        if node.text != text
          node.replace Nokogiri::HTML.fragment text
        end
      end
    end

    def do_process_macro(fragment, substitute, declared_macro, options, post_process)
      registered_macro = find_macro(declared_macro)
      descriptor = registered_macro.actual_descriptor
      if descriptor.post_process? && !post_process
        # do not replace the substitute, as it will be processed during
        # the post_process stage
        substitute
      else
        actual_options = options
        if descriptor.post_process? && post_process
          actual_options = adjust_post_process_options(fragment, options)
        end
        instance = registered_macro.macro.new(view)
        instance.execute declared_macro[:args], **actual_options
      end
    rescue => error
      # define a default instance so we can reuse error handling provided by MacroBase
      if instance.nil?
        instance = OpenProject::TextFormatting::Macros::MacroBase.new(view)
      end
      error_descriptor = create_error_descriptor(error, declared_macro, descriptor)
      instance.handle_error(error_descriptor).to_s
    end

    #
    # attempts to find a macro in the macro registry.
    #
    def find_macro(declared_macro)
      qname = declared_macro[:qname]
      result = OpenProject::TextFormatting::Macros::Internal::MacroRegistry.instance.find(qname)
      raise "Unknown macro: #{qname}" if result.nil?
      result
    end

    #
    # creates a new instance of error descriptor for consumption by MacroBase#handle_error
    #
    def create_error_descriptor(error, declared_macro, descriptor)
      if descriptor.nil?
        OpenProject::TextFormatting::Macros::UnknownMacroErrorDescriptor
          .new error, declared_macro: declared_macro
      else
        OpenProject::TextFormatting::Macros::MacroErrorDescriptor
          .new error, declared_macro: declared_macro, descriptor: descriptor
      end
    end

    #
    # adjusts options by adding the currently processed fragment for post_process stage
    # macros such as TocMacro
    #
    def adjust_post_process_options(fragment, options)
      # post_process macros must be able to modify the fragment, e.g. TocMacro
      result = options.dup
      result[:fragment] = fragment
      result
    end

    OPF_ESCAPE = 'opf:escape' unless const_defined?(:OPF_ESCAPE)

    def transform_macro_node(node)
      index = @macros.length
      @macros << {
        qname: node.name,
        args: extract_macro_args(node),
        escape: !!node.attributes[OPF_ESCAPE]
      }
      node.replace node.document.create_text_node("{{opf:macro:#{index}}}")
    end

    def extract_macro_args(node)
      result = determine_args_from_attributes node
      # TODO:coy:might break with XML content?
      if node.children.length > 0 && !node.inner_html.blank?
        result[OpenProject::TextFormatting::Macros::MacroBase::OPF_CONTENT] =
          node.inner_html
      end
      # ensure that the macro can access the keys using symbols
      result.symbolize_keys!
      result
    end

    def determine_args_from_attributes(node)
      result = {}
      node.attributes.map do |attr|
        unless attr[0] == OPF_ESCAPE
          result[attr[0]] = attr[1].value
        end
      end
      result
    end

    LEGACY_TOC_RE = /(\{\{(<|>)toc\}\})/ unless const_defined?(:LEGACY_TOC_RE)

    def transform_legacy_toc(text)
      text.gsub!(LEGACY_TOC_RE) do |_m|
        align = $2
        if align == '<'
          '{{toc(left)}}'
        else
          '{{toc(right)}}'
        end
      end
    end

    MACROS_RE = /
                (!)?                        # escaping
                (
                \{\{                        # opening tag
                ([\w]+)                     # macro name
                (\(([^\}]*)\))?             # optional arguments
                \}\}                        # closing tag
                )
                /x unless const_defined?(:MACROS_RE)

    def transform_legacy_macros(text)
      text.gsub!(MACROS_RE) do
        esc = $1
        qname = "legacy:#{$3}"
        args = ($5 || '').split(',').each(&:strip!)
        index = @macros.length
        @macros << {
          qname: qname,
          args: args,
          escape: !!esc
        }
        "{{opf:macro:#{index}}}"
      end
    end

    # since we are required to use Nokogiri::XML instead of Nokogiri:HTML,
    # which loses custom namespace prefixes on parse, we need to adjust
    # HTML attributes that do not have a value, e.g. opf:escape,
    # with <attr>="true", as otherwise these will be lost by Nokogiri::XML
    def transform_boolean_attributes(text)
      # TODO:coy:matches trailing / and associates it with the attrs
      text.gsub!(/(<\w+(?::\w+)?)(\s+)([^>]+)?([\/]?>)/m) do |_m|
        leading = $1
        ws = $2
        attrs = $3
        closing = $4
        if attrs[-1] == '/'
          attrs = attrs[0..-2]
          closing = '/' + closing
        end
        unless attrs.nil?
          attrs.gsub!(/(\w+(?::\w+)?)((\s+)|$)/m) do |_m|
            attr = $1
            tws = $3
            "#{attr}=\"true\"#{tws}"
          end
        end
        "#{leading}#{ws}#{attrs}#{closing}"
      end
    end

    def process_escaped_macro(declared_macro) #, descriptor)
      ''
      #throw NotImplementedError.new
    end
  end
end
