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
module WorkPackage::Exports
  module Formatters
    module PDF
      class CompoundDoneRatio < ::Exports::Formatters::Default
        def self.apply?(name, export_format)
          name.to_sym == :done_ratio && export_format == :pdf
        end

        def format(work_package, **)
          derived_done_ratio = work_package.derived_done_ratio
          derived = derived_done_ratio&.positive? ? " · Σ #{format_value(derived_done_ratio)}" : ""
          "#{format_value(work_package.done_ratio)}#{derived}"
        end

        def format_value(value, _options = {})
          return "" if value.nil?

          "#{value}%"
        end
      end
    end
  end
end
