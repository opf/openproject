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
  # Marks a type or variant as the default for new projects. The flag is unique
  # within a family, so the previous holder among the root and its variants is
  # unmarked in the same transaction.
  class MakeDefaultService
    def initialize(type:, user:)
      @type = type
      @user = user
    end

    def call
      Type.transaction do
        previous_defaults.each { |member| member.update!(is_default: false) }
        type.update!(is_default: true)
      end

      ServiceResult.success(result: type)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(result: type, errors: e.record.errors)
    end

    private

    attr_reader :type, :user

    def previous_defaults
      type.family.select { |member| member != type && member.is_default? }
    end
  end
end
