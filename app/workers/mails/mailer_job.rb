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
# The `delivery_job` is customized to add the shared job setup required for
# OpenProject such as reloading the mailer configuration and resetting the
# request store on each job execution.
#
# It also adds retry logic to the job.
class Mails::MailerJob < ActionMailer::MailDeliveryJob
  include SharedJobSetup

  # Retry mailing jobs 14 times with polynomial backoff (retries for ~ 1.5 days).
  #
  # with polynomial backoff, the formula to get wait_duration is:
  #
  #   ((executions**4) + (Kernel.rand * (executions**4) * jitter)) + 2
  #
  # as the default jitter is 0.0, the formula becomes:
  #
  #   ((executions**4) + 2)
  #
  # To get the numbers, run this:
  #
  #     (1..20).reduce(0) do |total_wait, i|
  #       wait = (i**4) + 2
  #       total_wait += wait
  #       puts "Execution #{i} waits #{wait} secs. Total wait: #{total_wait} secs"
  #       total_wait
  #     end
  #
  # We set attemps to 14 to have it retry for 127715 seconds which is more than
  # 1 day (~= 1 day 11 hours 30 min)
  retry_on StandardError, wait: :polynomially_longer, attempts: 14
end
