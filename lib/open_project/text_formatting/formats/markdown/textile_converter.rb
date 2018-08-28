#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# This file is derived from the 'Redmine converter from Textile to Markown'
# https://github.com/Ecodev/redmine_convert_textile_to_markown
#
# Original license:
# Copyright (c) 2016
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative 'pandoc_wrapper'

module OpenProject::TextFormatting::Formats
  module Markdown
    class TextileConverter
      include ActionView::Helpers::TagHelper

      TAG_CODE = 'pandoc-unescaped-single-backtick'.freeze
      TAG_FENCED_CODE_BLOCK = 'force-pandoc-to-ouput-fenced-code-block'.freeze
      DOCUMENT_BOUNDARY = "TextileConverterDocumentBoundary09339cab-f4f4-4739-85b0-d02ba1f342e6".freeze
      BLOCKQUOTE_START = "TextileConverterBlockquoteStart09339cab-f4f4-4739-85b0-d02ba1f342e6".freeze
      BLOCKQUOTE_END = "TextileConverterBlockquoteEnd09339cab-f4f4-4739-85b0-d02ba1f342e6".freeze

      attr_reader :pandoc

      def initialize
        @pandoc = PandocWrapper.new
      end

      def run!
        puts 'Starting conversion of Textile fields to CommonMark+GFM.'

        puts 'Checking compatibility of your installed pandoc version.'
        pandoc.check_arguments!

        ActiveRecord::Base.transaction do
          converters.each(&:call)
        end

        puts "\n-- Completed --"
      end

      private

      def converters
        [
          method(:convert_settings),
          method(:convert_models),
          method(:convert_custom_field_longtext)
        ]
      end

      def convert_settings
        print 'Converting settings '
        Setting.welcome_text = convert_textile_to_markdown(Setting.welcome_text)
        print '.'

        Setting.registration_footer = Setting.registration_footer.dup.tap do |footer|
          footer.transform_values { |val| convert_textile_to_markdown(val) }
          print '.'
        end

        puts ' done'
      end

      ##
      # Converting model attributes as defined in +models_to_convert+.
      def convert_models
        models_to_convert.each do |klass, attributes|
          print "#{klass.name} "

          # Iterate in batches to avoid plucking too much
          with_original_values_in_batches(klass, attributes) do |orig_values|
            markdowns_in_groups = bulk_convert_textile_with_fallback(orig_values, attributes)
            new_values = new_values_for(attributes, orig_values, markdowns_in_groups)

            next if new_values.empty?

            ActiveRecord::Base.connection.execute(batch_update_statement(klass, attributes, new_values))
          end
          puts ' done'
        end
      end

      def convert_custom_field_longtext
        formattable_cfs = CustomField.where(field_format: 'text').pluck(:id)
        print "CustomField type text "
        CustomValue.where(custom_field_id: formattable_cfs).in_batches(of: 200) do |relation|
          relation.pluck(:id, :value).each do |cv_id, value|
            CustomValue.where(id: cv_id).update_all(value: convert_textile_to_markdown(value))
            print '.'
          end
        end

        puts ' done'
      end

      # Iterate in batches to avoid plucking too much
      def with_original_values_in_batches(klass, attributes)
        batches_of_objects_to_convert(klass, attributes) do |relation|
          orig_values = relation.pluck(:id, *attributes)

          yield orig_values
        end
      end

      def bulk_convert_textile_with_fallback(orig_values, attributes)
        old_values = orig_values.inject([]) do |former_values, values|
          former_values + values.drop(1)
        end

        joined_textile = concatenate_textile(old_values)

        markdown = convert_textile_to_markdown(joined_textile)

        markdowns_in_groups = []

        begin
          markdowns_in_groups = split_markdown(markdown).each_slice(attributes.length).to_a
        rescue StandardError
          # Don't do anything. Let the subsequent code try to handle it again
        end

        if markdowns_in_groups.length != orig_values.length
          # Error handling: Some textile seems to be misformed e.g. <pre>something</pre (without closing >).
          # In such cases, handle texts individually to avoid the error affecting other texts
          markdowns = old_values.map do |old_value|
            convert_textile_to_markdown(old_value)
          end

          markdowns_in_groups = markdowns.each_slice(attributes.length).to_a
        end

        markdowns_in_groups
      end

      def new_values_for(attributes, orig_values, markdowns_in_groups)
        new_values = []
        orig_values.each_with_index do |values, index|
          new_values << { id: values[0] }.merge(attributes.zip(markdowns_in_groups[index]).to_h)

          print '.'
        end

        new_values
      end

      def convert_textile_to_markdown(textile)
        return '' unless textile.present?

        cleanup_before_pandoc(textile)

        markdown = execute_pandoc_with_stdin! textile

        if markdown.empty?
          markdown
        else
          cleanup_after_pandoc(markdown)
        end
      end

      def execute_pandoc_with_stdin!(textile)
        pandoc.execute! textile
      rescue Timeout::Error => e
        warn "Execution of pandoc failed: #{e}"
        ''
      rescue StandardError => e
        raise "Execution of pandoc failed: #{e}"
      end

      def models_to_convert
        {
          ::Announcement => [:text],
          ::AttributeHelpText => [:help_text],
          ::Comment => [:comments],
          ::WikiContent => [:text],
          ::WorkPackage =>  [:description],
          ::Message => [:content],
          ::News => [:description],
          ::Board => [:description],
          ::Project => [:description],
          ::Journal => [:notes],
          ::Journal::MessageJournal => [:content],
          ::Journal::WikiContentJournal => [:text],
          ::Journal::WorkPackageJournal => [:description],
          ::AttributeHelpText => [:help_text]
        }
      end

      def batches_of_objects_to_convert(klass, attributes)
        scopes = attributes.map { |attribute| klass.where.not(attribute => nil).where.not(attribute => '') }

        scope = scopes.shift
        scopes.each do |attribute_scope|
          scope = scope.or(attribute_scope)
        end

        # Iterate in batches to avoid plucking too much
        scope.in_batches(of: 50) do |relation|
          yield relation
        end
      end

      def batch_update_statement(klass, attributes, values)
        if OpenProject::Database.mysql?
          batch_update_statement_mysql(klass, attributes, values)
        else
          batch_update_statement_postgresql(klass, attributes, values)
        end
      end

      def batch_update_statement_postgresql(klass, attributes, values)
        table_name = klass.table_name
        sets = attributes.map { |a| "#{a} = new_values.#{a}" }.join(', ')
        new_values = values.map do |value_hash|
          text_values = value_hash.except(:id).map { |_, v| ActiveRecord::Base.connection.quote(v) }.join(', ')
          "(#{value_hash[:id]}, #{text_values})"
        end

        <<-SQL
          UPDATE #{table_name}
          SET
            #{sets}
          FROM (
            VALUES
             #{new_values.join(', ')}
          ) AS new_values (id, #{attributes.join(', ')})
          WHERE #{table_name}.id = new_values.id
        SQL
      end

      def batch_update_statement_mysql(klass, attributes, values)
        table_name = klass.table_name
        sets = attributes.map { |a| "#{table_name}.#{a} = new_values.#{a}" }.join(', ')
        new_values_union = values.map do |value_hash|
          text_values = value_hash.except(:id).map { |k, v| "#{ActiveRecord::Base.connection.quote(v)} AS #{k}" }.join(', ')
          "SELECT #{value_hash[:id]} AS id, #{text_values}"
        end.join(' UNION ')

        <<-SQL
          UPDATE #{table_name}, (#{new_values_union}) AS new_values
          SET
            #{sets}
          WHERE #{table_name}.id = new_values.id
        SQL
      end

      def concatenate_textile(textiles)
        textiles.join("\n\n#{DOCUMENT_BOUNDARY}\n\n")
      end

      def split_markdown(markdown)
        markdown.split("\n\n#{DOCUMENT_BOUNDARY}\n\n")
      end

      def cleanup_before_pandoc(textile)
        placeholder_for_inline_code_at(textile)
        drop_table_colspan_notation(textile)
        drop_table_alignment_notation(textile)
        move_class_from_code_to_pre(textile)
        remove_code_inside_pre(textile)
        convert_malformed_textile(textile)
        remove_empty_paragraphs(textile)
        replace_numbered_headings(textile)
        add_newline_to_avoid_lazy_blocks(textile)
        remove_spaces_before_table(textile)
        wrap_blockquotes(textile)
      end

      def cleanup_after_pandoc(markdown)
        # Remove the \ pandoc puts before * and > at begining of lines
        markdown.gsub!(/^((\\[*>])+)/) { $1.gsub("\\", "") }

        # Add a blank line before lists
        # But do not apply it to *emphasis* or **strong** at the start of a line (whitespace is important)
        markdown.gsub!(/^([^*].*)\n\* /, "\\1\n\n* ")

        # Remove the injected tag
        markdown.gsub!(' ' + TAG_FENCED_CODE_BLOCK, '')

        # Replace placeholder with real backtick
        markdown.gsub!(TAG_CODE, '`')

        # Un-escape Redmine link syntax to wiki pages
        markdown.gsub!('\[\[', '[[')
        markdown.gsub!('\]\]', ']]')

        # replace filtered out span with ins
        markdown.gsub!(/<span class="underline">(.+)<\/span>/, '<ins>\1</ins>')

        markdown.gsub!(/#{BLOCKQUOTE_START}\n(.+?)\n\n#{BLOCKQUOTE_END}/m) do
          $1.gsub(/([\n])([^\n]*)/, '\1> \2')
        end

        # Create markdown links from !image!:link syntax
        # ![alt](image])
        markdown.gsub! /(?<image>\!\[[^\]]*\]\([^\)]+\)):(?<link>https?:\S+)/,
                       '[\k<image>](\k<link>)'

        convert_macro_syntax(markdown)

        markdown
      end

      # Convert old {{macroname(args)}} syntax to <macro class="macroname" data-arguments="">
      def convert_macro_syntax(markdown)
        old_macro_regex = /
            (!)?                        # escaping
            (
            \{\{                        # opening tag
            ([\w\\_]+)                  # macro name
            (\(([^\}]*)\))?             # optional arguments
            \}\}                        # closing tag
            )
          /x

        markdown.gsub!(old_macro_regex) do
          esc = $1
          all = $2
          macro = $3.gsub('\_', '_')
          args = $5 || ''
          args_array = args.split(',').each(&:strip!)
          data = {}

          # Escaped macros should probably render as before?
          next all if esc.present?

          case macro
          when 'timeline'
            next content_tag :macro, I18n.t('macros.legacy_warning.timeline'), class: 'legacy-macro -macro-unavailable'
          when 'hello_world'
            next ''
          when 'include'
            macro = 'include_wiki_page'
            data[:page] = args
          when 'create_work_package_link'
            data[:type] = args_array[0] if args_array.length >= 1
            data[:classes] = args_array[1] if args_array.length >= 2
          else
            data[:arguments] = args if args.present?
          end

          content_tag :macro, '', class: macro, data: data
        end
      end

      # OpenProject support @ inside inline code marked with @ (such as "@git@github.com@"), but not pandoc.
      # So we inject a placeholder that will be replaced later on with a real backtick.
      def placeholder_for_inline_code_at(textile)
        textile.gsub!(/@([\S]+@[\S]+)@/, TAG_CODE + '\\1' + TAG_CODE)
      end

      # Drop table colspan/rowspan notation ("|\2." or "|/2.") because pandoc does not support it
      # See https://github.com/jgm/pandoc/issues/22
      def drop_table_colspan_notation(textile)
        textile.gsub!(/\|[\/\\]\d\. /, '| ')
      end

      # Drop table alignment notation ("|>." or "|<." or "|=.") because pandoc does not support it
      # See https://github.com/jgm/pandoc/issues/22
      def drop_table_alignment_notation(textile)
        textile.gsub!(/\|[<>=]\. /, '| ')
      end

      # Move the class from <code> to <pre> so pandoc can generate a code block with correct language
      def move_class_from_code_to_pre(textile)
        textile.gsub!(/(<pre)(><code)( class="[^"]*")(>)/, '\\1\\3\\2\\4')
      end

      # Remove the <code> directly inside <pre>, because pandoc would incorrectly preserve it
      def remove_code_inside_pre(textile)
        textile.gsub!(/(<pre[^>]*>)<code>/, '\\1')
        textile.gsub!(/<\/code>(<\/pre>)/, '\\1')
      end

      # Some malformed textile content make pandoc run extremely slow,
      # so we convert it to proper textile before hitting pandoc
      # see https://github.com/jgm/pandoc/issues/3020
      def convert_malformed_textile(textile)
        textile.gsub!(/-          # (\d+)/, "* \\1")
      end

      # Remove empty paragraph blocks which trip up pandoc
      def remove_empty_paragraphs(textile)
        textile.gsub!(/\np(=|>)?\.[\s\.]*\n/, '')
      end

      # Replace numbered headings as they are not supported in commonmark/gfm
      def replace_numbered_headings(textile)
        textile.gsub!(/h(\d+)#./, 'h\\1.')
      end

      # Add an additional newline before:
      # * every pre block prefixed by only one newline
      #   as indented code blocks do not interrupt a paragraph and also do not have precedence
      #   compared to a list which might also be indented.
      # * every table prefixed by only one newline (if the line before isn't a table already)
      # * every blockquote prefixed by one newline (if the line before isn't a blockquote)
      def add_newline_to_avoid_lazy_blocks(textile)
        textile.gsub!(/(\n[^>|]+)\r?\n(\s*)(<pre>|\||>)/, "\\1\n\n\\2\\3")
      end

      # Remove spaces before a table as that would lead to the table
      # not being identified
      def remove_spaces_before_table(textile)
        textile.gsub!(/(^|\n)\s+(\|.+\|)\s*/, "\n\n\\2\n")
      end

      # Wrap all blockquote blocks into boundaries as `>` is not valid blockquote syntax and would thus be
      # escaped
      def wrap_blockquotes(textile)
        textile.gsub!(/(([\n]>[^\n]*)+)/m) do
          "\n#{BLOCKQUOTE_START}\n" + $1.gsub(/([\n])> *([^\n]*)/, '\1\2') + "\n\n#{BLOCKQUOTE_END}\n"
        end
      end
    end
  end
end
