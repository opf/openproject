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

require 'open_project/text_formatting/transformers'

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
    extend ActiveSupport::Concern
    extend DeprecatedAlias

    include SimpleTextFormatting
    include Redmine::WikiFormatting::Macros::Definitions
    include ActionView::Helpers::SanitizeHelper
    include ERB::Util # for h()
    include Redmine::I18n
    include ActionView::Helpers::TextHelper
    include OpenProject::ObjectLinking
    # The WorkPackagesHelper is required to get access to the methods
    # 'work_package_css_classes' and 'work_package_quick_info'.
    include WorkPackagesHelper

    # Formats text according to system settings.
    # 2 ways to call this method:
    # * with a String: format_text(text, options)
    # * with an object and one of its attribute: format_text(issue, :description, options)
    def format_text(*args)
      text, options = parse_args *args
      # don't return html in edit mode when textile or text formatting is enabled
      return text if text.blank? or options[:edit]

      # the order of processors is important as most processors will operate on the direct
      # child axis of the currently processed fragment, only
      processors = [
        Transformers::RedmineLinkTransformer.new(current_request, @controller),
        Transformers::WikiLinkTransformer.new(current_request, @controller),
        Transformers::RedmineWikiTransformer.new(current_request, @controller),
        # must run after redmine*/wiki link transformers
        Transformers::MacroTransformer.new(current_request, @controller),
        # must run after post_process macro expansion
        Transformers::ImageAttachmentTransformer.new(current_request, @controller)
      ]

      fragment = Nokogiri::XML.fragment text

      # preprocess old style macros, etc.
      processors.each do |processor|
        if processor.respond_to?(:pre_process)
          fragment = processor.pre_process(fragment, options)
        end
      end

      # process link formatting, wiki markup, macros, etc.
      processors.each do |processor|
        if processor.respond_to?(:process)
          fragment = processor.process(fragment, options)
          fragment
        end
      end

      # post process post processing macros, etc.
      processors.each do |processor|
        if processor.respond_to?(:post_process)
          fragment = processor.post_process(fragment, options)
        end
      end

      text = escape_non_macros(fragment.to_s)
      text.html_safe
    end
    deprecated_alias :textilizable, :format_text
    deprecated_alias :textilize,    :format_text

    private

    def parse_args(*args)
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

      options[:project] = options[:project] || @project || (obj && obj.respond_to?(:project) ? obj.project : nil)
      options[:edit] = !!options[:edit]
      # offer 'plain' as readable version for 'no formatting' to callers
      options_format = options[:format] == 'plain' ? '' : options[:format]
      options[:format] = options_format || Setting.text_formatting

      [text, options]
    end

    ##
    # Escape double curly braces after macro expansion.
    # This will avoid arbitrary angular expressions to be evaluated in
    # formatted text marked html_safe.
    def escape_non_macros(text)
      text.gsub(/\{\{(?! \$root\.DOUBLE_LEFT_CURLY_BRACE)/, '{{ $root.DOUBLE_LEFT_CURLY_BRACE }}')
    end

    def parse_non_pre_blocks(text)
      s = StringScanner.new(text)
      tags = []
      parsed = ''
      while !s.eos?
        s.scan(/(.*?)(<(\/)?(pre|code)(.*?)>|\z)/im)
        text = s[1]
        full_tag = s[2]
        closing = s[3]
        tag = s[4]
        if tags.empty?
          yield text
        end
        parsed << text
        if tag
          if closing
            if tags.last == tag.downcase
              tags.pop
            end
          else
            tags << tag.downcase
          end
          parsed << full_tag
        end
      end
      # Close any non closing tags
      while tag = tags.pop
        parsed << "</#{tag}>"
      end
      parsed
    end

    def current_request
      request rescue nil
    end
  end
end
