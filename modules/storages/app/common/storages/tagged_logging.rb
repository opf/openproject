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

module Storages
  module TaggedLogging
    delegate :info, :error, to: :logger

    # @param tag [Class, String, Array<Class, String>] the tag or list of tags to annotate the logs with
    # @yield [Logger]
    def with_tagged_logger(tag = self.class, &)
      logger.tagged(*tag, &)
    end

    # @param storage_error [Storages::StorageError] an instance of Storages::StorageError
    # @param context [Hash{Symbol => Object}] extra metadata that will be appended to the logs
    def log_storage_error(storage_error, context = {})
      payload = storage_error.data&.payload
      data =
        case payload
        in { status: Integer }
          { status: payload&.status, body: payload&.body.to_s }
        else
          payload.to_s
        end

      error_message = context.merge({ error_code: storage_error.code, message: storage_error.log_message, data: })
      error error_message
    end

    def log_validation_error(validation_result, context = {})
      # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
      error context.merge({ validation_message: validation_result.errors.to_h })
      # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
    end

    def logger
      Rails.logger
    end
  end
end
