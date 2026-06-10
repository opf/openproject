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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Journal::EventConfiguration
  class << self
    DEFAULT = true

    # Allows controlling whether event callbacks (workflows, aggregation jobs) are triggered
    # for created/updated journals. After the block is executed, the setting is returned to
    # its original state which is true by default.
    # In case the method is called multiple times within itself, the first setting prevails.
    def with(trigger_callbacks, &)
      if trigger_callbacks.nil?
        yield
      elsif already_set?
        log_warning(trigger_callbacks)
        yield
      else
        with_first(trigger_callbacks, &)
      end
    end

    def active?
      @active ||= Concurrent::ThreadLocalVar.new(DEFAULT)
      @active.value
    end

    protected

    def with_first(trigger_callbacks)
      old_value = active?
      self.already_set = true

      self.active = trigger_callbacks

      yield
    ensure
      self.active = old_value
      self.already_set = false
    end

    def log_warning(trigger_callbacks)
      return if active? == trigger_callbacks

      message = <<~MSG
        Ignoring setting journal event callbacks to '#{trigger_callbacks}' as a parent block already set it to #{active?}
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
