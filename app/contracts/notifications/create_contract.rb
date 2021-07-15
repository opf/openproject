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

module Notifications
  class CreateContract < ::ModelContract
    CHANNELS = %i[ian mail mail_digest].freeze

    attribute :recipient
    attribute :subject
    attribute :reason_ian
    attribute :reason_mail
    attribute :reason_mail_digest
    attribute :project
    attribute :actor
    attribute :resource
    attribute :journal
    attribute :resource_type
    attribute :read_ian
    attribute :read_mail
    attribute :read_mail_digest

    validate :validate_recipient_present
    validate :validate_reason_present
    validate :validate_channels

    def validate_recipient_present
      errors.add(:recipient, :blank) if model.recipient.blank?
    end

    def validate_reason_present
      CHANNELS.each do |channel|
        errors.add(:"reason_#{channel}", :no_notification_reason) if read_channel_without_reason?(channel)
      end
    end

    def validate_channels
      if CHANNELS.map { |channel| read_channel(channel) }.compact.empty?
        errors.add(:base, :at_least_one_channel)
      end

      CHANNELS.each do |channel|
        errors.add(:"read_#{channel}", :read_on_creation) if read_channel(channel)
      end
    end

    def read_channel_without_reason?(channel)
      read_channel(channel) == false && model.send(:"reason_#{channel}").nil?
    end

    def read_channel(channel)
      model.send(:"read_#{channel}")
    end
  end
end
