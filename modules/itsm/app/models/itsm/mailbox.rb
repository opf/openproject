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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ITSM
  module Mailbox
    extend ActiveSupport::Concern

    included do
      belongs_to :project, optional: false

      self.filter_attributes += %i[password]

      normalizes :username, with: ->(username) { username.strip }

      validate :connection_uses_its_protocol, if: :connection
      # Community edition limit: more mailboxes per project need the Enterprise edition (ITSM-21).
      validate :project_has_no_other_mailbox, if: :project
      validates :username, :password, presence: true
    end

    def credentials = Credentials.new(username:, password:)

    private

    def connection_uses_its_protocol
      errors.add(:connection, :invalid) unless connection.protocol == self.class::PROTOCOL
    end

    def project_has_no_other_mailbox
      errors.add(:project, :mailbox_limit_reached) if other_mailboxes.exists?(project_id:)
    end

    def other_mailboxes = self.class.where.not(id:)
  end
end
