# Textile to Markdown converter
# Based on redmine_convert_textile_to_markown
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

require 'open3'

module OpenProject::TextFormatting::Formatters
  module Markdown
    class TextileConverter
      attr_reader :src, :dst

      def initialize
      end


      def run!
        puts 'Starting conversion of Textile fields to CommonMark+GFM.'

        ActiveRecord::Base.transaction do
          converters.each do |handler|
            handler.call
          end
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

        puts 'done'
      end

      ##
      # Converting model attributes as defined in +models_to_convert+.
      def convert_models
        models_to_convert.each do |the_class, attributes|
          print "#{the_class.name} "

          # Iterate in batches to avoid plucking too much
          the_class.in_batches(of: 200) do |relation|
            relation.pluck(:id, *attributes).each do |values|
              # Zip converted texts into
              # { attr_a: textile, ... }
              converted = values.drop(1).map(&method(:convert_textile_to_markdown))
              update_hash = Hash[attributes.zip(converted)]
              the_class.where(id: values.first).update_all(update_hash)

              print '.'
            end
          end
          puts 'done'
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

        puts 'done'
    end

      def convert_textile_to_markdown(textile)
        return '' unless textile.present?

        # Redmine support @ inside inline code marked with @ (such as "@git@github.com@"), but not pandoc.
        # So we inject a placeholder that will be replaced later on with a real backtick.
        tag_code = 'pandoc-unescaped-single-backtick'
        textile.gsub!(/@([\S]+@[\S]+)@/, tag_code + '\\1' + tag_code)

        # Drop table colspan/rowspan notation ("|\2." or "|/2.") because pandoc does not support it
        # See https://github.com/jgm/pandoc/issues/22
        textile.gsub!(/\|[\/\\]\d\. /, '| ')

        # Drop table alignement notation ("|>." or "|<." or "|=.") because pandoc does not support it
        # See https://github.com/jgm/pandoc/issues/22
        textile.gsub!(/\|[<>=]\. /, '| ')

        # Move the class from <code> to <pre> so pandoc can generate a code block with correct language
        textile.gsub!(/(<pre)(><code)( class="[^"]*")(>)/, '\\1\\3\\2\\4')

        # Remove the <code> directly inside <pre>, because pandoc would incorrectly preserve it
        textile.gsub!(/(<pre[^>]*>)<code>/, '\\1')
        textile.gsub!(/<\/code>(<\/pre>)/, '\\1')

        # Inject a class in all <pre> that do not have a blank line before them
        # This is to force pandoc to use fenced code block (```) otherwise it would
        # use indented code block and would very likely need to insert an empty HTML
        # comment "<!-- -->" (see http://pandoc.org/README.html#ending-a-list)
        # which are unfortunately not supported by Redmine (see http://www.redmine.org/issues/20497)
        tag_fenced_code_block = 'force-pandoc-to-ouput-fenced-code-block'
        textile.gsub!(/([^\n]<pre)(>)/, "\\1 class=\"#{tag_fenced_code_block}\"\\2")

        # Force <pre> to have a blank line before them
        # Without this fix, a list of items containing <pre> would not be interpreted as a list at all.
        textile.gsub!(/([^\n])(<pre)/, "\\1\n\n\\2")

        # Some malformed textile content make pandoc run extremely slow,
        # so we convert it to proper textile before hitting pandoc
        # see https://github.com/jgm/pandoc/issues/3020
        textile.gsub!(/-          # (\d+)/, "* \\1")

        # TODO pandoc recommends format 'gfm' but that isnt available in current LTS
        # markdown_github, which is deprecated, is however available.
        command = %w(pandoc --wrap=preserve -f textile -t markdown_github)
        markdown, stderr_str, status = Open3.capture3(*command, stdin_data: textile)

        raise "Pandoc failed: #{stderr_str}" unless status.success?

        # Remove the \ pandoc puts before * and > at begining of lines
        markdown.gsub!(/^((\\[*>])+)/) { $1.gsub("\\", "") }

        # Add a blank line before lists
        markdown.gsub!(/^([^*].*)\n\*/, "\\1\n\n*")

        # Remove the injected tag
        markdown.gsub!(' ' + tag_fenced_code_block, '')

        # Replace placeholder with real backtick
        markdown.gsub!(tag_code, '`')

        # Un-escape Redmine link syntax to wiki pages
        markdown.gsub!('\[\[', '[[')
        markdown.gsub!('\]\]', ']]')

        # Un-escape Redmine quotation mark "> " that pandoc is not aware of
        markdown.gsub!(/(^|\n)&gt; /, "\n> ")

        return markdown
      end

      def models_to_convert
        {
          ::Announcement => [:text],
          ::AttributeHelpText => [:help_text],
          ::Comment => [:text],
          ::WikiContent => [:text],
          ::WorkPackage =>  [:description],
          ::Message => [:content],
          ::News => [:description],
          ::Project => [:description],
          ::Journal => [:notes],
          ::Journal::AttachmentJournal => [:description],
          ::Journal::MessageJournal => [:content],
          ::Journal::WikiContentJournal => [:text],
          ::Journal::WorkPackageJournal => [:description],
          ## TODO
          # Documents
          # ::Document => [:description],
          # Meetings
        }
      end
    end
  end
end
