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
    class ColumnHeaderComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      # There might be a lot of possible duplicates, restrict it to some magic number.
      NAMED_DUPLICATES = 3

      def initialize(profile:, duplicates:, same_as_type:)
        super()

        @profile = profile
        @duplicates = duplicates
        @same_as_type = same_as_type
      end

      private

      attr_reader :profile, :duplicates

      def variant = profile.variant

      def name = variant.display_name

      def same_as_type? = @same_as_type

      def duplicate? = duplicates.any?

      def duplicate_names
        names = duplicates.first(NAMED_DUPLICATES).map { it.variant.display_name }
        remaining = duplicates.size - names.size
        return names.to_sentence if remaining.zero?

        t("types.comparison.labels.duplicate_of_more", names: names.to_sentence, count: remaining)
      end

      def configuration_path = type_settings_path(**variant.path_args)
    end
  end
end
