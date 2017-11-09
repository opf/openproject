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

module OpenProject::TextFormatting
  module Formatters
    class << self

      def registered
        unless defined? @formatters
          register_default!
        end

        @formatters
      end

      def registered?(key)
        registered.key? key.to_sym
      end

      def register(namespace:)
        # Force lookup to avoid const errors later on.
        key = namespace.to_sym
        modulename = namespace.to_s.classify

        raise ArgumentError, "format name '#{name}' is already taken" if registered?(key)

        begin
          formatter = "OpenProject::TextFormatting::Formatters::#{modulename}::Formatter".constantize
          helper = "OpenProject::TextFormatting::Formatters::#{modulename}::Helper".constantize
          registered[key] = { formatter: formatter, helper: helper }
        rescue NameError => e
          Rails.logger.error "Failed to register wiki formatting #{namespace}: #{e}"
          Rails.logger.debug { e.backtrace }
        end
      end

      def formatter_for(name)
        entry = registered.fetch(name.to_sym) { registered[:null_formatter] }
        entry[:formatter]
      end

      def helper_for(name)
        entry = registered.fetch(name.to_sym) { registered[:null_formatter] }
        entry[:helper]
      end

      def format_names
        registered.keys.map
      end

      private

      def register_default!
        @formatters = {}
        register namespace: :null_formatter
        register namespace: :textile
      end
    end
  end
end
