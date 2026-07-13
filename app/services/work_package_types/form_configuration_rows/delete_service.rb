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
  module FormConfigurationRows
    class DeleteService < ::BaseServices::BaseCallable
      include ::WorkPackageTypes::FormConfiguration::Concern

      def initialize(user:, type:, row_key:)
        super(user:, type:)
        @row_key = row_key
      end

      def perform
        row = find_row(@row_key)
        return failure_with_message(I18n.t("types.edit.form_configuration.not_found")) unless row

        attributes = row[:group].attributes.dup
        attributes.delete_at(row[:index])
        row[:group].attributes = attributes

        persist_groups(active_groups).tap do |call|
          call.result = row[:group] if call.success?
        end
      end
    end
  end
end
