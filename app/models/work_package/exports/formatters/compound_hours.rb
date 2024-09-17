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
module WorkPackage::Exports
  module Formatters
    class CompoundHours < ::Exports::Formatters::Default
      def self.apply?(name, _export_format)
        name.to_sym == key
      end

      def format(work_package, **)
        hours = format_value(work_package.public_send(attribute))
        derived_hours = total_prefix(format_value(work_package.public_send(:"derived_#{attribute}")))

        [hours, derived_hours].compact.join(" ").presence
      end

      def format_value(value, _options = nil)
        DurationConverter.output(value)
      end

      private

      def attribute
        self.class.key
      end

      def total_prefix(value)
        value && "· Σ #{value}"
      end
    end
  end
end
