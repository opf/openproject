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
  # This module provides utility methods to work with PostgreSQL's full-text capabilities (TSVECTOR)
  module FullTextSearch
    DISALLOWED_CHARACTERS = /['?\\:()&|!*<>]/

    def self.tsv_where(table_name, column_name, value, options = { concatenation: :and, normalization: :text })
      if OpenProject::Database.allows_tsv?
        column = '"' + table_name.to_s + '"."' + column_name.to_s + '_tsv"'
        query = tokenize(value, options[:concatenation], options[:normalization])
        language = OpenProject::Configuration.main_content_language

        ActiveRecord::Base.send(
          :sanitize_sql_array, ["#{column} @@ to_tsquery(?, ?)",
                                language,
                                query]
        )
      end
    end

    def self.tokenize(text, concatenation = :and, normalization = :text)
      terms = normalize(clean_terms(text), normalization).split(/[\s]+/).reject(&:blank?)

      case concatenation
      when :and
        # all terms need to hit
        terms.join ' & '
      when :and_not
        # all terms must not hit.
        '! ' + terms.join(' & ! ')
      end
    end

    def self.normalize(text, type = :text)
      case type
      when :text
        normalize_text(text)
      when :filename
        normalize_filename(text)
      end
    end

    def self.normalize_text(text)
      I18n.with_locale(:en) { I18n.transliterate(text.to_s.downcase) }
    end

    def self.normalize_filename(filename)
      name_in_words = to_words filename.to_s.downcase
      I18n.with_locale(:en) { I18n.transliterate(name_in_words) }
    end

    def self.to_words(text)
      text.gsub /[^[:alnum:]]/, ' '
    end

    def self.clean_terms(terms)
      terms.gsub(DISALLOWED_CHARACTERS, ' ')
    end
  end
end
