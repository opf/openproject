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

require 'ruby-progressbar'
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

      attr_reader :pandoc, :logger

      def initialize
        @logger = ::OpenProject::Logging::TeeLogger.new 'markdown-migration'
        @pandoc = PandocWrapper.new logger
      end

      def run!
        # We're going to decrease the AR logger to avoid dumping all SQL inserts
        # in the output logs
        current_ar_log_level = ActiveRecord::Base.logger.level

        begin
          logger.info 'Starting conversion of Textile fields to CommonMark.'

          logger.info 'Decreasing ActiveRecord logger to avoid flooding your logs.'
          ActiveRecord::Base.logger.level = :error

          logger.info 'Checking compatibility of your installed pandoc version.'
          pandoc.check_arguments!

          ActiveRecord::Base.transaction do
            converters.each(&:call)
          end

          logger.info "\n-- Completed --"
        ensure
          ActiveRecord::Base.logger.level = current_ar_log_level
        end
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
        logger.info 'Converting settings '
        Setting.welcome_text = convert_textile_to_markdown(Setting.welcome_text)

        Setting.registration_footer = Setting.registration_footer.dup.tap do |footer|
          footer.transform_values { |val| convert_textile_to_markdown(val) }
        end
      end

      ##
      # Converting model attributes as defined in +models_to_convert+.
      def convert_models
        models_to_convert.each do |klass, attributes|
          logger.info "Converting #{klass.name.pluralize} "

          # Iterate in batches to avoid plucking too much
          with_original_values_in_batches(klass, attributes) do |orig_values|
            markdowns_in_groups = bulk_convert_textile_with_fallback(klass, orig_values, attributes)
            new_values = new_values_for(attributes, orig_values, markdowns_in_groups)

            next if new_values.empty?

            ActiveRecord::Base.connection.execute(batch_update_statement(klass, attributes, new_values))
          end
        end
      end

      def convert_custom_field_longtext
        formattable_cfs = CustomField.where(field_format: 'text').pluck(:id)
        logger.info "CustomField type text "
        scope = CustomValue.where(custom_field_id: formattable_cfs)
        progress = ProgressBar.create(title: "Formattable CustomValues", total: scope.count)
        scope.in_batches(of: 200) do |relation|
          relation.pluck(:id, :value).each do |cv_id, value|
            CustomValue.where(id: cv_id).update_all(value: convert_textile_to_markdown(value))
            progress.increment
          end
        end
        progress.finish
      end

      # Iterate in batches to avoid plucking too much
      def with_original_values_in_batches(klass, attributes)
        batches_of_objects_to_convert(klass, attributes) do |relation, progress|
          orig_values = relation.pluck(:id, *attributes)

          result = yield orig_values
          progress.progress += orig_values.count

          result
        end
      end

      def bulk_convert_textile_with_fallback(klass, orig_values, attributes)
        old_values = orig_values.inject([]) do |former_values, values|
          former_values + values.drop(1)
        end

        joined_textile = concatenate_textile(old_values)

        markdowns_in_groups = []

        begin
          markdown = convert_textile_to_markdown(joined_textile,  raise_on_timeout: true)
          markdowns_in_groups = split_markdown(markdown).each_slice(attributes.length).to_a
        rescue StandardError => e
          # Don't do anything. Let the subsequent code try to handle it again
        end

        if markdowns_in_groups.length != orig_values.length
          # Error handling: Some textile seems to be misformed e.g. <pre>something</pre (without closing >).
          # In such cases, handle texts individually to avoid the error affecting other texts
          progress = ProgressBar.create(title: "Converting items individually due to pandoc mismatch", total: orig_values.length)
          markdowns = old_values.each_with_index.map do |old_value, index|
            convert_textile_to_markdown(old_value, raise_on_timeout: false)
          rescue StandardError
            logger.error "Failing to convert single document #{klass.name} ##{orig_values[index].first}. "
            non_convertible_textile_doc(old_value)
          ensure
            progress.increment
          end

          markdowns_in_groups = markdowns.each_slice(attributes.length).to_a
          progress.finish
        end

        markdowns_in_groups
      end

      def new_values_for(attributes, orig_values, markdowns_in_groups)
        new_values = []
        orig_values.each_with_index do |values, index|
          new_values << { id: values[0] }.merge(attributes.zip(markdowns_in_groups[index]).to_h)
        end

        new_values
      end

      def convert_textile_to_markdown(textile, raise_on_timeout: false)
        return '' unless textile.present?

        cleanup_before_pandoc(textile)

        markdown = execute_pandoc_with_stdin! textile, raise_on_timeout

        if markdown.empty?
          markdown
        else
          cleanup_after_pandoc(markdown)
        end
      end

      def execute_pandoc_with_stdin!(textile, raise_on_timeout)
        pandoc.execute! textile
      rescue Timeout::Error => e

        if raise_on_timeout
          logger.error <<~TIMEOUT_WARN
            Execution of pandoc timed out: #{e}.

            You may want to increase the timeout
            (OPENPROJECT_PANDOC_TIMEOUT_SECONDS, currently at #{pandoc.pandoc_timeout} seconds)
          TIMEOUT_WARN

          raise e
        else
          logger.error <<~TIMEOUT_WARN
            Execution of pandoc timed out: #{e}.

            The document will not be replaced (probably due to syntax errors) because pandoc did not finish.
            If you're running PostgreSQL: You can try to cancel this run and retry the migration and with an increased timeout
            (OPENPROJECT_PANDOC_TIMEOUT_SECONDS, currently at #{pandoc.pandoc_timeout} seconds).

            If you're running MySQL: You need to restore your pre-upgrade backup first since it does not have transactional DDL.

            However, please note that pandoc sometimes trip up over specific textile parts that cause it to run indefinitely.
            In this case, you will have to manually fix the textile and increasing the timeout will achieve nothing.
          TIMEOUT_WARN

          non_convertible_textile_doc(textile)
        end
      rescue StandardError => e
        logger.error "Execution of pandoc failed: #{e}"
        raise e
      end

      def non_convertible_textile_doc(textile)
        <<~DOC
          # Warning: This document could not be converted, probably due to syntax errors.
          The below content is textile.


          <pre>

          #{textile}

          </pre>
        DOC
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
        progress = ProgressBar.create(title: "Conversion", starting_at: 0, total: scope.count)
        scope.in_batches(of: 50) do |relation|
          yield relation, progress
        end
        progress.finish
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
        hard_breaks_within_multiline_tables(textile)
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

        # remove the escaping from links within parenthesis having a trailing slash
        # ([description](https://some/url/\))
        markdown.gsub! /\((?<pretext>.*?)\[(?<description>.*?)\]\((?<link>.*?)\\\)\)/,
                       '(\k<pretext>[\k<description>](\k<link>))'

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
        textile.gsub!(/^\s+(\|.+?\|)/, "\n\n\\1")
      end

      ##
      # Redmine introduced hard breaks to support multiline tables that are not official
      # textile. We detect tables with line breaks and replace them with <br/>
      # https://www.redmine.org/projects/redmine/repository/revisions/2824/diff/
      def hard_breaks_within_multiline_tables(textile)
        content_regexp = %r{
          (?<=\|) # Assert beginning table pipe lookbehind
          ([^\|]{5,}) # Non-empty content
          (?=\|) # Assert ending table pipe lookahead
        }mx

        # Match all textile tables
        textile.gsub!(/^(\|.+?\|)$/m) do |table|
          table.gsub(content_regexp) { |table_content| table_content.gsub("\n", " <br/> ") }
        end
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
