#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module OpenProject
  module SyntaxHighlighting
    class << self
      # Highlights +text+ as the content of +filename+
      # Should not return line numbers nor outer pre tag
      # use CodeRay to scan normal text, since it's smart enough to find
      # the correct source encoding before passing it to ERB::Util.html_escape
      def highlight_by_filename(text, filename)
        language = guess_lexer(text, filename)

        highlight_by_language(text, language)
      end

      # Highlights +text+ using +language+ syntax
      def highlight_by_language(text, language, formatter = Rouge::Formatters::HTML.new)
        Rouge.highlight(text, language, formatter).html_safe
      end

      ##
      # Guesses the appropriate lexer for the given text using rouge's guesser
      # Can be used to extract information using the lexer's name, tag, desc methods
      def guess_lexer(text, filename = nil)
        guessers = [Rouge::Guessers::Source.new(text)]
        guessers << Rouge::Guessers::Filename.new(filename) if filename.present?

        begin
          Rouge::Lexer::guess guessers: guessers
        rescue StandardError => e
          if !e.message.nil? && e.message == 'Ambiguous guess: can\'t decide between ["html", "xml"]'
            Rouge::Lexers::HTML.new
          else
            raise e
          end
        end
      end
    end
  end
end
