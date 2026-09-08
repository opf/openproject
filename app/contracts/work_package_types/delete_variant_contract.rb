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
  class DeleteVariantContract < ::ModelContract
    include AuthorizesVariantAuthoring

    def self.model = TypeVariant

    validate :variant_is_named
    validate :migration_target_is_available

    private

    # A type is nothing without a configuration to fall back on, so its base variant goes only
    # when the type does.
    def variant_is_named
      errors.add(:base, :is_default_variant) if model.is_default_variant?
    end

    def migration_target_is_available
      target = options[:target]

      errors.add(:base, :migration_target_invalid) if target && model.migration_targets.exclude?(target)
    end
  end
end
