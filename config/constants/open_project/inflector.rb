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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  class Inflector < Zeitwerk::GemInflector
    alias_method :default_inflect, :camelize

    def camelize(basename, abspath)
      self.class.camelize_rules.each do |rule|
        name = instance_exec(basename, abspath, &rule)

        return name if name
      end

      super
    end

    private

    def overrides
      self.class.inflections.merge(super)
    end

    class << self
      def rule(&block)
        camelize_rules << block
      end

      def camelize_rules
        @camelize_rules ||= []
      end

      def inflections
        @inflections ||= {}
      end

      def inflection(overrides)
        inflections.merge!(overrides)
      end
    end
  end
end
