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

module OpenProject
  module Appsignal
    module_function

    def enabled?
      ENV["APPSIGNAL_ENABLED"] == "true"
    end

    def logging_enabled?
      enabled? && ENV["APPSIGNAL_SEND_APPLICATION_LOGS"] == "true"
    end

    def exception_handler(message, log_context = {})
      if (exception = log_context[:exception])
        if ::Appsignal::Transaction.current?
          ::Appsignal.set_error(exception) do |transaction|
            transaction.set_tags tags(log_context)
          end
        else
          ::Appsignal.send_error(exception) do |transaction|
            transaction.set_tags tags(log_context)
          end
        end
      else
        Rails.logger.warn "Ignoring non-exception message for appsignal #{message.inspect}"
      end
    end

    ##
    # Add current user and other stateful tags to appsignal
    # @param context A hash of context, such as passing in the current controller or request
    def tag_request(context = {})
      return unless enabled?

      payload = tags(context)
      ::Appsignal.tag_request(payload)
    end

    ##
    # Tags to be added for Appsignal
    def tags(context)
      OpenProject::Logging.extend_payload!(default_payload, context)
    end

    ##
    # Default payload to add for appsignal
    def default_payload
      {
        locale: I18n.locale,
        version: OpenProject::VERSION.to_semver,
        core_hash: OpenProject::VERSION.revision,
        core_version: OpenProject::VERSION.core_sha,
        product_version: OpenProject::VERSION.product_sha
      }.compact
    end
  end
end
