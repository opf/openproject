#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# Requires including class to implement #notification_mail.
class MailNotificationJob
  mattr_accessor :raise_exceptions

  def initialize(recipient_id, author_id)
    @recipient_id = recipient_id
    @author_id    = author_id
  end

  def perform
    execute_as recipient do
      notify
    end
  rescue ActiveRecord::RecordNotFound => e
    # Expecting this error if recipient user was deleted intermittently.
    # Since we cannot recover from this error we catch it and move on.
    Rails.logger.error "Cannot deliver notification (#{self.inspect})
                        as required record was not found: #{e}".squish
    raise e if raise_exceptions
  end

  def error(_job, e)
    Rails.logger.error "notification failed (#{self.inspect}): #{e}"
  end

  protected

  def recipient
    @recipient ||= Principal.find(@recipient_id)
  end

  def author
    @author ||= Principal.find(@author_id)
  end

  private

  def notify
    notification_mail.deliver
  end

  def execute_as(user)
    previous_user = User.current
    User.current = user
    yield
  ensure
    User.current = previous_user
  end
end
