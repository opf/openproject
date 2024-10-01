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

# OpenProject is configured to use this job when sending emails like this:
#
# ```
# UserMailer.some_mail("some param").deliver_later
# ```
#
# This job is used because all our `XxxMailer` classes inherit from
# `ApplicationMailer`, and `ApplicationMailer.delivery_job` is set to
# `::Mails::MailerJob`.
#
# The `delivery_job` is customized because we want to have the sending of the
# email run in an instance inheriting from `ApplicationJob` instead of a
# `ActionMailer::MailDeliveryJob` (Rails default delivery job). Indeed
# `ApplicationJob` contains all the shared setup required for OpenProject such
# as reloading the mailer configuration and resetting the request store.
class Mails::MailerJob < ApplicationJob
  # Retry mailing jobs three times with polinomial backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # The following lines are copied from ActionMailer::MailDeliveryJob
  queue_as do
    mailer_class = arguments.first.constantize
    mailer_class.deliver_later_queue_name
  end

  rescue_from StandardError, with: :handle_exception_with_mailer_class

  def perform(mailer, mail_method, delivery_method, args:, kwargs: nil, params: nil)
    mailer_class = params ? mailer.constantize.with(params) : mailer.constantize
    message =
      if kwargs
        mailer_class.public_send(mail_method, *args, **kwargs)
      else
        mailer_class.public_send(mail_method, *args)
      end
    message.send(delivery_method)
  end

  private

  # "Deserialize" the mailer class name by hand in case another argument
  # (like a Global ID reference) raised DeserializationError.
  def mailer_class
    if mailer = Array(@serialized_arguments).first || Array(arguments).first
      mailer.constantize
    end
  end

  def handle_exception_with_mailer_class(exception)
    if klass = mailer_class
      klass.handle_exception exception
    else
      raise exception
    end
  end
end
