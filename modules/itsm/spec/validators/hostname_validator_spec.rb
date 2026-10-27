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

require "spec_helper"
require_module_spec_helper

RSpec.describe HostnameValidator do
  subject(:record) { model_class.new(host:) }

  let(:model_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :host

      validates :host, hostname: true

      def self.name = "HostnameRecord"
    end
  end

  %w[imap.mailbox.org IMAP.Mailbox.ORG localhost mail-1.example.com].each do |valid_host|
    context "with #{valid_host}" do
      let(:host) { valid_host }

      it { is_expected.to be_valid }
    end
  end

  %w[
    192.168.1.10
    ::1
    imap.mailbox.org/inbox
    -imap.example.com
    imap-.example.com
    imap..example.com
    imap_1.example.com
  ].each do |invalid_host|
    context "with #{invalid_host}" do
      let(:host) { invalid_host }

      it { is_expected.not_to be_valid }
    end
  end

  context "without a host" do
    let(:host) { "" }

    it { is_expected.to be_valid }
  end
end
