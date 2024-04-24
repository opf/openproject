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

class Seeder
  class << self
    attr_writer :logger

    def logger
      @logger ||= Rails.logger
    end

    def log_to_stdout!
      @logger = Logger.new($stdout)
      @logger.level = Logger::DEBUG
      @logger.formatter = proc do |_severity, _datetime, _prog_name, msg|
        "#{msg}\n"
      end
    end
  end

  class_attribute :needs, default: []

  attr_reader :seed_data

  def initialize(seed_data = nil)
    @seed_data = seed_data
  end

  def seed!
    if applicable?
      without_notifications do
        seed_data!
      end
    else
      Seeder.logger.debug { "   *** #{not_applicable_message}" }
      lookup_existing_references
    end
  end

  def seed_data!
    raise NotImplementedError
  end

  def applicable?
    true
  end

  # Called if the seeding is not applicable to have a chance to lookup
  # existing records and set some references to them.
  def lookup_existing_references; end

  def not_applicable_message
    "Skipping #{self.class.name}"
  end

  # The user being the author of all data created during seeding.
  def admin_user
    @admin_user ||= User.not_builtin.admin.first
  end

  protected

  def print_status(message)
    Seeder.logger.info message

    yield if block_given?
  end

  def print_error(message)
    Seeder.logger.error message
  end

  def without_notifications(&)
    Journal::NotificationConfiguration.with(false, &)
  end
end
