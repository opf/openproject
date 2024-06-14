# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Storages
  module ProjectStorages
    class CopyProjectFoldersService
      def self.call(source:, target:)
        new.call(source, target)
      end

      def initialize
        @data = Adapters::ResultData::CopyTemplateFolder
          .new(id: nil, polling_url: nil, requires_polling: false)
      end

      def call(source, target)
        return ServiceResult.success(result: @data) if source.project_folder_inactive?
        return ServiceResult.success(result: @data.with(id: source.project_folder_id)) if source.project_folder_manual?

        auth_strategy = Peripherals::Registry.resolve("#{source.storage.short_provider_type}.authentication.userless").call

        Peripherals::Registry
          .resolve("#{source.storage.short_provider_type}.commands.copy_template_folder")
          .call(auth_strategy:,
                storage: source.storage,
                source_path: source.project_folder_location,
                destination_path: target.managed_project_folder_path)
      end
    end
  end
end
