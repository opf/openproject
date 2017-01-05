#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module OpenProject
  module SimpleTextFormatting
    # Truncates and returns the string as a single line
    def truncate_single_line(string, *args)
      truncate(string.to_s, *args).gsub(%r{[\r\n]+}m, ' ').html_safe
    end

    # Truncates at line break after 250 characters or options[:length]
    # TODO:unused?
    def truncate_lines(string, options = {})
      length = options[:length] || 250
      if string.to_s =~ /\A(.{#{length}}.*?)$/m
        "#{$1}..."
      else
        string
      end
    end
  end

  module TextFormatting
    require 'open_project/text_formatting/macros/provided'

    include SimpleTextFormatting

    extend ActiveSupport::Concern
    extend DeprecatedAlias

    # Formats text according to system settings.
    # 2 ways to call this method:
    # * with a String: format_text(text, options)
    # * with an object and one of its attribute: format_text(issue, :description, options)
    def format_text(*args)
      text, options = PrivateMethods::parse_args args, @project
      # don't return html in edit mode when textile or text formatting is enabled
      return text if text.blank? or options[:edit]

      fragment = PrivateMethods::do_process text, options, self

      fragment.to_s.html_safe
    end
    deprecated_alias :textilizable, :format_text
    deprecated_alias :textilize,    :format_text

    def current_request
      request
    rescue
      nil
    end

    # prevent the following private methods from leaking into the including context
    module PrivateMethods
      require 'open_project/text_formatting/internal/transformers'

      def self.prepare_processors(view)
        # the order of processors is important and must not be changed
        processors = [
          # must run before all other processors during the process stage
          OpenProject::TextFormatting::Internal::Transformers::RedmineWikiTransformer.new(view),
          OpenProject::TextFormatting::Internal::Transformers::RedmineLinkTransformer.new(view),
          OpenProject::TextFormatting::Internal::Transformers::WikiLinkTransformer.new(view),
          # must run after redmine*/wiki link transformers during the
          # process stage
          OpenProject::TextFormatting::Internal::Transformers::MacroTransformer.new(view),
          # the below two must run after macro transformer during the
          # post process stage
          OpenProject::TextFormatting::Internal::Transformers::ImageAttachmentTransformer.new(view),
          # WTF?: all occurrences of {{ have already been replaced by {{ $root... }} by whatever
          # is responsible for doing so
          #OpenProject::TextFormatting::Internal::Transformers::NGExpressionTransformer.new(view)
        ]
        result = {}
        [:legacy_pre_process, :pre_process, :process, :post_process].each do |stage|
          result[stage] = processors.select do |transformer|
            transformer.respond_to? stage
          end
        end
        result
      end

      def self.do_process(text, options, view)
        processors = prepare_processors view

        processed_text = text.dup

        # legacy preprocess stage for dealing with text that could interfere
        # with nokogiri's parsing of the fragment, e.g. {{<toc}}
        processors[:legacy_pre_process].each do |processor|
          processed_text = processor.legacy_pre_process processed_text, **options
        end

        fragment = Nokogiri::XML.fragment processed_text

        [:pre_process, :process, :post_process].each do |stage|
          processors[stage].each do |processor|
            fragment = processor.send stage, fragment, **options
          end
        end

        fragment
      end

      def self.parse_args(args, project)
        options = args.last.is_a?(Hash) ? args.pop : {}

        case args.size
        when 1
          obj = options[:object]
          text = args.shift
        when 2
          options[:object] = obj = args.shift
          options[:attr] = attr = args.shift
          text = obj.send(attr).to_s
        else
          raise ArgumentError, 'invalid arguments to format_text'
        end

        prepare_options options, obj, project

        [text, options]
      end

      def self.prepare_options(options, obj, project)
        options[:project] = options[:project] || project || (
          obj && obj.respond_to?(:project) ? obj.project : nil
        )
        options[:edit] = !!options[:edit]
        # offer 'plain' as readable version for 'no formatting' to callers
        options_format = options[:format] == 'plain' ? '' : options[:format]
        options[:format] = options_format || Setting.text_formatting
        options[:attachments] = options[:attachments] || (
          obj && obj.respond_to?(:attachments) ? obj.attachments : nil
        )
      end
    end
  end
end
