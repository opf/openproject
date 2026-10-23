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
  class MailServer < ApplicationRecord
    has_many :mailboxes, class_name: "ITSM::Mailbox", inverse_of: :mail_server, dependent: :restrict_with_error
    has_many :health_reports, as: :subject, dependent: :delete_all

    enum :imap_encryption, { tls: "tls", starttls: "starttls" }, prefix: true, validate: true
    enum :smtp_encryption, { tls: "tls", starttls: "starttls" }, prefix: true, validate: true

    normalizes :imap_host, :smtp_host, with: ->(host) { host.strip.downcase.delete_suffix(".") }

    validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
    validates :imap_host, :smtp_host, presence: true, hostname: true
    validates :imap_port, :smtp_port, numericality: { only_integer: true, in: 1..65_535 }

    def imap = Connection.new(host: imap_host, port: imap_port, encryption: imap_encryption)
    def smtp = Connection.new(host: smtp_host, port: smtp_port, encryption: smtp_encryption)
  end
end
