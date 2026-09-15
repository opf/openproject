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
    class CellComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(cell:)
        super()

        @cell = cell
      end

      private

      attr_reader :cell

      delegate :row, :profile, :count, :same_as_base, to: :cell

      def variant = profile.variant

      def format = row.format

      def linked? = variant.linked?(row.aspect)

      def source = variant.source_for(row.aspect)

      def source_path = helpers.aspect_edit_path(source, row.aspect)

      def projects_path = edit_type_projects_path(**variant.path_args)

      def owner_path = project_settings_work_packages_types_path(variant.project)

      def muted(text) = render(Primer::Beta::Text.new(color: :muted)) { text }
    end
  end
end
