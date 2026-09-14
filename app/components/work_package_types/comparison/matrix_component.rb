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

module WorkPackageTypes
  module Comparison
    # One collapsible section per group of rows, each a Primer BorderBox. Columns line up across
    # the sections through a grid template every row shares.
    class MatrixComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      LABEL_WIDTH = 200
      COLUMN_WIDTH = 240

      def initialize(comparison:)
        super()

        @comparison = comparison
      end

      private

      attr_reader :comparison

      delegate :columns, :sections, :type, to: :comparison

      def grid_style
        "grid-template-columns: #{LABEL_WIDTH}px repeat(#{columns.size}, minmax(#{COLUMN_WIDTH}px, 1fr))"
      end

      def section_label(section) = t("types.comparison.sections.#{section}")

      def row_label(row) = t(row.label_key)

      def row_id(row) = "comparison-#{row.section}-#{row.key}"

      def section_id(section) = "comparison-section-#{section}"

      def duplicates_of(profile) = comparison.duplicates_of(profile)
    end
  end
end
