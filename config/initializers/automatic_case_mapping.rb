# frozen_string_literal: true

#-- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# In Turkish, "I/ı" and "İ/i" are different letters. Therefore, "i".upcase is
# not "I" for this language. This initializer prepend a module to String and
# Symbol to automatically use the turkic case mapping if current user is using
# Turkish language.
#
# See https://docs.ruby-lang.org/en/3.4/case_mapping_rdoc.html.
module AutomaticCaseMapping
  # Both Turkish and Azerbaijani use the turkic case mapping rules
  TURKIC_LOCALES = %w[tr az].freeze

  def self.use_turkic_case_mapping?(options)
    options.empty? && User.current&.language&.in?(TURKIC_LOCALES)
  # during reloading, `User` and `User.current` may not be available
  rescue StandardError, LoadError
    false
  end

  def self.create_module(methods)
    Module.new do
      methods.each do |method|
        define_method(method) do |*options|
          if AutomaticCaseMapping.use_turkic_case_mapping?(options)
            super(:turkic)
          else
            super(*options)
          end
        end
      end
    end
  end
end

AutomaticCaseMappingForString = AutomaticCaseMapping.create_module(
  %i[
    capitalize
    capitalize!
    downcase
    downcase!
    upcase
    upcase!
    swapcase
    swapcase!
  ]
)

AutomaticCaseMappingForSymbol = AutomaticCaseMapping.create_module(
  %i[
    capitalize
    downcase
    upcase
    swapcase
  ]
)

# Rails.application.config.after_initialize do
#   String.prepend(AutomaticCaseMappingForString)
#   Symbol.prepend(AutomaticCaseMappingForSymbol)
# end
