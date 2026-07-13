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

class PermittedParams
  module AllowedSettings
    class Restriction
      attr_reader :restricted_keys, :condition

      def initialize(restricted_keys, condition)
        @restricted_keys = restricted_keys
        @condition = condition
      end

      def applicable?
        if condition.respond_to? :call
          condition.call
        else
          condition
        end
      end
    end

    module_function

    def all
      keys = Settings::Definition.all.keys

      restrictions.select(&:applicable?).each do |restriction|
        keys -= restriction.restricted_keys
      end

      keys
    end

    def filters
      restricted_keys = Set.new(self.restricted_keys)
      Settings::Definition.all.flat_map do |key, definition|
        next if restricted_keys.include?(key)

        case definition.format
        when :hash
          { key => {} }
        when :array
          { key => [] }
        else
          key
        end
      end
    end

    def restricted_keys
      restrictions.select(&:applicable?)
                  .flat_map(&:restricted_keys)
    end

    def add_restriction!(keys:, condition:)
      restrictions << Restriction.new(keys, condition)
    end

    def restrictions
      @restrictions ||= []
    end

    def init!
      password_keys = %i(
        password_min_length
        password_active_rules
        password_days_valid
        password_count_former_banned
        lost_password
      )

      add_restriction!(
        keys: password_keys,
        condition: -> { OpenProject::Configuration.disable_password_login? }
      )

      add_restriction!(
        keys: %i(registration_footer),
        condition: -> { !Setting.registration_footer_writable? }
      )
    end

    init!
  end
end
