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

module Storages::Peripherals
  module StorageErrorHelper
    def raise_service_result_error(errors)
      handle_base_errors(errors) if errors.has_key?(:base)

      api_errors = ::API::Errors::ErrorBase.create_errors(errors)
      fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
    end

    def handle_base_errors(errors)
      base_errors = errors.symbols_for(:base)
      message = errors.full_messages_for(:base)&.first

      if base_errors.include? :not_found
        fail API::Errors::OutboundRequestNotFound.new(message)
      elsif base_errors.include? :unauthorized
        fail ::API::Errors::Unauthenticated.new(message)
      elsif base_errors.include? :forbidden
        fail API::Errors::OutboundRequestForbidden.new(message)
      elsif base_errors.include? :error
        fail API::Errors::InternalError.new(message)
      else
        base_errors
      end
    end

    def raise_error(error)
      Rails.logger.error(error)

      case error.code
      when :not_found
        raise API::Errors::OutboundRequestNotFound.new
      when :bad_request
        raise API::Errors::BadRequest.new(error.log_message)
      when :forbidden
        raise API::Errors::OutboundRequestForbidden.new
      when :missing_ee_token_for_one_drive
        raise API::Errors::EnterpriseTokenMissing.new
      else
        raise API::Errors::InternalError.new(error.log_message)
      end
    end
  end
end
