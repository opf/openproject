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

class Mails::DeliverJob < ApplicationJob
  queue_with_priority :notification

  def perform(recipient_id)
    self.recipient_id = recipient_id

    return if abort?

    deliver_mail
  end

  private

  attr_accessor :recipient_id

  def abort?
    # nothing to do if recipient was deleted in the meantime
    recipient.nil?
  end

  def deliver_mail
    mail = User.execute_as(recipient) { build_mail }

    mail&.deliver_now
  end

  # To be implemented by subclasses.
  # Returns a Mail::Message, or nil if no message should be sent.
  def render_mail
    raise NotImplementedError, 'SubclassResponsibility'
  end

  def build_mail
    render_mail
  rescue NotImplementedError
    # Notify subclass of the need to implement
    raise
  rescue StandardError => e
    Rails.logger.error "#{self.class.name}: Unexpected error rendering a mail: #{e}"
    # not raising, to avoid re-schedule of DelayedJob; don't expect render errors to fix themselves
    # by retrying
    nil
  end

  def recipient
    @recipient ||= if recipient_id.is_a?(User)
                     recipient_id
                   else
                     User.find_by(id: recipient_id)
                   end
  end
end
