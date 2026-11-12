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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages::Peripherals
  module StorageErrorHelper
    def raise_service_result_error(errors)
      handle_base_errors(errors) if errors.has_key?(:base)

      api_errors = ::API::Errors::ErrorBase.create_errors(errors)
      fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
    end

    def handle_base_errors(errors)
      base_errors = errors.symbols_for(:base).to_set
      message = error_message_for(errors)

      if base_errors.include? :not_found
        fail API::Errors::OutboundRequestNotFound.new(message)
      elsif base_errors.include? :unauthorized
        fail ::API::Errors::Unauthenticated.new(message)
      elsif base_errors.include? :forbidden
        fail API::Errors::OutboundRequestForbidden.new(message)
      elsif base_errors.include? :error
        fail API::Errors::SafeInternalError.new(message)
      else
        base_errors
      end
    end

    def error_message_for(error, attr = :base)
      error.full_messages_for(attr)&.first
    rescue I18n::MissingTranslationData
      nil
    end

    def raise_error(error)
      Rails.logger.error(error)

      # FIXME: messages were removed we need to deal with it - 2025-04-14 @mereghost

      case error.code
      when :not_found
        raise API::Errors::OutboundRequestNotFound.new
      when :bad_request
        raise API::Errors::BadRequest.new(error.code)
      when :forbidden
        raise API::Errors::OutboundRequestForbidden.new
      when :missing_ee_token_for_one_drive
        raise API::Errors::EnterpriseTokenMissing.new
      else
        raise API::Errors::SafeInternalError.new(error.code)
      end
    end
  end
end
