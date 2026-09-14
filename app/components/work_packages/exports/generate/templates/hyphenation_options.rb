# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module WorkPackages
  module Exports
    module Generate
      module Templates
        module HyphenationOptions
          # This is a list of languages that are supported by the hyphenation library
          # https://rubygems.org/gems/text-hyphen
          # The labels are the language names in the language itself (NOT to be put I18n)
          def hyphenation_options
            [
              { label: "-", value: "" },
              { label: "Català", value: "ca" },
              { label: "Dansk", value: "da" },
              { label: "Deutsch", value: "de" },
              { label: "Eesti", value: "et" },
              { label: "English", value: "en" },
              { label: "Español", value: "es" },
              { label: "Euskara", value: "eu" },
              { label: "Français", value: "fr" },
              { label: "Gaeilge", value: "ga" },
              { label: "Hrvatski", value: "hr" },
              { label: "Indonesia", value: "id" },
              { label: "Interlingua", value: "ia" },
              { label: "Italiano", value: "it" },
              { label: "Magyar", value: "hu" },
              { label: "Melayu", value: "ms" },
              { label: "Nederlands", value: "nl" },
              { label: "Norsk", value: "no" },
              { label: "Polski", value: "pl" },
              { label: "Português", value: "pt" },
              { label: "Slovenčina", value: "sk" },
              { label: "Suomi", value: "fi" },
              { label: "Svenska", value: "sv" },
              { label: "Ísland", value: "is" },
              { label: "Čeština", value: "cs" },
              { label: "Монгол", value: "mn" },
              { label: "Русский", value: "ru" }
            ]
          end

          def hyphenation_language_by_locale
            search_locale = I18n.locale.to_s
            hyphenation_options.find { |lang| lang[:value] == search_locale }
          end
        end
      end
    end
  end
end
