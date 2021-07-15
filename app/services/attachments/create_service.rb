#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Attachments::CreateService < ::BaseServices::Create
  include Attachments::TouchContainer

  around_call :error_wrapped_call

  ##
  # Create an attachment service bypassing the user-provided whitelist
  # for internal purposes such as exporting data.
  #
  # @param user The user to call the service with
  # @param whitelist A custom whitelist to validate with, or empty to disable validation
  #
  # Warning: When passing an empty whitelist, this results in no validations on the content type taking place.
  def self.bypass_whitelist(user:, whitelist: [])
    new(user: user, contract_options: { whitelist: whitelist.map(&:to_s) })
  end

  def persist(call)
    attachment = call.result
    if attachment.container
      in_container_mutex(attachment.container) { super }
    else
      super
    end
  end

  def in_container_mutex(container)
    OpenProject::Mutex.with_advisory_lock_transaction(container) do
      yield.tap do
        # Get the latest attachments to ensure having them all for journalization.
        # We just created an attachment and a different worker might have added attachments
        # in the meantime, e.g when bulk uploading.
        container.attachments.reload
      end
    end
  end

  def after_perform(call)
    attachment = call.result
    container = attachment.container

    touch(container) unless container.nil?

    OpenProject::Notifications.send(
      OpenProject::Events::ATTACHMENT_CREATED,
      attachment: attachment
    )

    call
  end

  def error_wrapped_call
    yield
  rescue StandardError => e
    log_attachment_saving_error(e)

    message =
      if e&.class&.to_s == 'Errno::EACCES'
        I18n.t('api_v3.errors.unable_to_create_attachment_permissions')
      else
        I18n.t('api_v3.errors.unable_to_create_attachment')
      end
    raise message
  end

  def log_attachment_saving_error(error)
    message = "Failed to save attachment: #{error&.class} - #{error&.message || 'Unknown error'}"

    OpenProject.logger.error message
  end
end
