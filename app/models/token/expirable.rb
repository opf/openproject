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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Token
  module Expirable
    extend ActiveSupport::Concern

    DEFAULT_EXPIRY = 30.days

    included do
      scope :expired, -> { where(expires_on: ...Time.current) }
      scope :not_expired, -> { where(expires_on: nil).or(where(expires_on: Time.current..)) }

      validate :validate_expires_on_in_future, if: :expires_on_changed?
      validate :validate_expires_on_date
    end

    class_methods do
      def find_by_plaintext_value(input)
        token = super
        token unless token&.expired?
      end
    end

    def expired?
      expires_on.present? && expires_on.past?
    end

    def expires_on_date
      expires_on&.in_time_zone(user.time_zone)&.to_date
    end

    def expires_on_date=(date_or_iso_string)
      @expires_on_date_error = nil

      date = case date_or_iso_string
             when Date then date_or_iso_string
             when String then Date.iso8601(date_or_iso_string)
             end

      self.expires_on = date&.in_time_zone(user.time_zone)&.end_of_day
    rescue Date::Error
      @expires_on_date_error = date_or_iso_string.blank? ? :blank : :not_a_date
    end

    private

    def validate_expires_on_in_future
      errors.add(:expires_on, :datetime_must_be_in_future) if expired?
    end

    def validate_expires_on_date
      errors.add(:expires_on, @expires_on_date_error) if @expires_on_date_error
    end
  end
end
