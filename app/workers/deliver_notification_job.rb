#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class DeliverNotificationJob < ApplicationJob
  def initialize(recipient_id, sender_id)
    @recipient_id = recipient_id
    @sender_id = sender_id
  end

  def perform
    # nothing to do if recipient was deleted in the meantime
    return unless recipient

    mail = User.execute_as(recipient) { build_mail }
    if mail
      mail.deliver_now
    end
  end

  private

  # To be implemented by subclasses.
  # Actual recipient and sender User objects are passed (always non-nil).
  # Returns a Mail::Message, or nil if no message should be sent.
  def render_mail(recipient:, sender:)
    raise 'SubclassResponsibility'
  end

  def build_mail
    render_mail(recipient: recipient, sender: sender)
  rescue StandardError => e
    Rails.logger.error "#{self.class.name}: Unexpected error rendering a mail: #{e}"
    # not raising, to avoid re-schedule of DelayedJob; don't expect render errors to fix themselves
    # by retrying
    nil
  end

  def recipient
    @recipient ||= User.find_by(id: @recipient_id)
  end

  def sender
    @sender ||= User.find_by(id: @sender_id) || DeletedUser.first
  end
end
