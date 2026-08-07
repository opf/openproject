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

module Projects
  module Types
    # Whether a project may move from one member of a type family to another.
    #
    # The pair being switched arrives through the contract options rather than off the model:
    # a switch changes which member the project resolves to, which is a row in project_types
    # rather than an attribute of the project the contract validates.
    class SwitchVariantContract < ManageTypesContract
      validate :validate_target_selectable

      protected

      def validate_target_selectable # rubocop:disable Metrics/AbcSize
        if target.nil?
          errors.add(:types, :switch_target_blank)
        elsif target == source
          errors.add(:types, :switch_target_identical)
        elsif source.root_id != target.root_id
          errors.add(:types, :switch_target_not_in_family)
        elsif !target_available_in_project?
          errors.add(:types, :switch_target_not_available)
        end
      end

      private

      def target_available_in_project?
        target.project_id.nil? || target.project_id == model.id
      end

      def source = options[:source]

      def target = options[:target]
    end
  end
end
