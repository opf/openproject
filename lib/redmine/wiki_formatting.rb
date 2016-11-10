#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

module Redmine
  module WikiFormatting
    @@formatters = {}

    class << self
      def map
        yield self
      end

      def register(name, formatter, helper)
        raise ArgumentError, "format name '#{name}' is already taken" if @@formatters[name.to_s]
        @@formatters[name.to_s] = { formatter: formatter, helper: helper }
      end

      def formatter_for(name)
        entry = @@formatters[name.to_s]
        (entry && entry[:formatter]) || Redmine::WikiFormatting::NullFormatter::Formatter
      end

      def helper_for(name)
        entry = @@formatters[name.to_s]
        (entry && entry[:helper]) || Redmine::WikiFormatting::NullFormatter::Helper
      end

      def format_names
        @@formatters.keys.map
      end

      def to_html(format, text, options = {}, &block)
        edit = !!options.delete(:edit)
        macros = catch_macros(text)
        formatter = lambda { formatter_for(format).new(text).to_html edit ? :edit : nil }
        if Setting.cache_formatted_text? && cache_store && text.size > 2.kilobyte
          cache_key = cache_key_for(format, options[:object], options[:attribute], options[:edit])
          # Text retrieved from the cache store may be frozen
          # We need to dup it so we can do in-place substitutions with gsub!
          text = cache_store.fetch cache_key do
            formatter.call()
          end.dup
        else
          text = formatter.call()
        end
        if macros
          inject_macros(text, macros, block, execute: block_given? && !edit)
        end
        text
      end

      # Returns a cache key for the given text +format+, +object+ and +attribute+ or nil if no caching should be done
      def cache_key_for(format, object, attribute, edit)
        if object && attribute && edit && !object.new_record? &&
           object.respond_to?(:updated_on) && !format.blank?
          "formatted_text/#{format}/#{object.class.model_name.cache_key}/" +
            "#{object.id}-#{attribute}-#{edit}-#{object.updated_on.to_s(:number)}"
        end
      end

      # Returns the cache store used to cache HTML output
      def cache_store
        ActionController::Base.cache_store
      end

      MACROS_RE = /(
                    (!)?                        # escaping
                    (
                    \{\{                        # opening tag
                    ([\w]+)                     # macro name
                    (\(([^\n\r]*)\))?           # optional arguments
                    ([\n\r].*?[\n\r])?          # optional block of text
                    \s*\}\}                     # closing tag, permit leading whitespace so that
                                                # macro_list will display correctly when using
                                                # here docs as desc
                    )
                  )/mx unless const_defined?(:MACROS_RE)

      MACROS_SUB_RE = /(
                        \{\{
                        macro\((\d+)\)
                        \}\}
                      )/x unless const_defined?(:MACROS_SUB_RE)

      # Extracts macros from text
      def catch_macros(text)
        macros = {}
        text.gsub!(MACROS_RE) do
          all = $1.try(:strip)
          macro = $4.downcase
          if Redmine::WikiFormatting::Macros.macro_exists?(macro) || all =~ MACROS_SUB_RE
            index = macros.size
            macros[index] = all
            "{{macro(#{index})}}"
          else
            all
          end
        end
        macros
      end

      # Macros substitution
      def inject_macros(text, macros, macros_runner, execute: true)
        text.gsub!(MACROS_SUB_RE) do
          index = $2.to_i
          orig = macros.delete(index)
          orig =~ MACROS_RE
          esc = $2
          macro = $4.downcase
          args = $6.to_s
          block = $7.try(:strip)
          if esc.nil? && execute
            begin
              macros_runner.call(macro, args, block)
            rescue => e
              "<span class=\"flash error macro-unavailable permanent\">\
              #{::I18n.t(:macro_execution_error, macro_name: macro)} (#{e})\
            </span>".squish
            rescue NotImplementedError
              "<span class=\"flash error macro-unavailable permanent\">\
              #{::I18n.t(:macro_unavailable, macro_name: macro)}\
            </span>".squish
            end
          else
            esc ? orig[1..orig.size] : orig
          end
        end
      end
    end
  end
end
