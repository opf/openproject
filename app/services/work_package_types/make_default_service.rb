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
  # Marks the configuration new projects start a type with. A new project applies one
  # configuration per type, so the sibling that held the flag is unmarked in the same
  # transaction — otherwise the promotion would only trip the variant's own validation.
  class MakeDefaultService
    def initialize(variant:, user:)
      @variant = variant
      @user = user
    end

    def call
      TypeVariant.transaction do
        previous_default&.update!(enabled_in_new_projects: false)
        variant.update!(enabled_in_new_projects: true)
      end

      ServiceResult.success(result: variant)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(result: variant, errors: e.record.errors)
    end

    private

    attr_reader :variant, :user

    def previous_default
      TypeVariant.where(type_id: variant.type_id).enabled_in_new_projects.where.not(id: variant.id).first
    end
  end
end
