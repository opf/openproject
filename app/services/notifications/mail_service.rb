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

class Notifications::MailService
  def initialize(notification)
    self.notification = notification
  end

  def call
    ensure_supported

    return if ian_read?

    strategy.send_mail(notification)
  end

  private

  attr_accessor :notification

  def ensure_supported
    unless supported?
      raise ArgumentError, "Sending mails for notifications is not supported for #{strategy_model}"
    end
  end

  def ian_read?
    notification.read_ian
  end

  def strategy
    @strategy ||= if self.class.const_defined?("#{strategy_model}Strategy")
                    "#{self.class}::#{strategy_model}Strategy".constantize
                  end
  end

  def strategy_model
    journal&.journable_type || resource&.class
  end

  def journal
    notification.journal
  end

  def resource
    notification.resource
  end

  def supported?
    strategy.present?
  end
end
