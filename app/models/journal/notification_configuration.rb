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

class Journal::NotificationConfiguration
  class << self
    DEFAULT = true

    # Allows controlling whether notifications are sent out for created journals.
    # After the block is executed, the setting is returned to its original state which is true by default.
    # In case the method is called multiple times within itself, the first setting prevails.
    # This allows to control the setting globally without having to pass the setting down the call stack in
    # order to ensure all subsequent code follows the provided setting.
    def with(send_notifications, &)
      if send_notifications.nil?
        yield
      elsif already_set?
        log_warning(send_notifications)
        yield
      else
        with_first(send_notifications, &)
      end
    end

    def active?
      @active ||= Concurrent::ThreadLocalVar.new(DEFAULT)
      @active.value
    end

    protected

    def with_first(send_notifications)
      old_value = active?
      self.already_set = true

      self.active = send_notifications

      yield
    ensure
      self.active = old_value
      self.already_set = false
    end

    def log_warning(send_notifications)
      return if active? == send_notifications

      message = <<~MSG
        Ignoring setting journal notifications to '#{send_notifications}' as a parent block already set it to #{active?}
      MSG
      Rails.logger.debug message.strip
    end

    def active=(value)
      @active.value = value
    end

    def already_set?
      @already_set ||= Concurrent::ThreadLocalVar.new(false)
      @already_set.value
    end

    def already_set=(value)
      @already_set.value = value
    end
  end
end
