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

RSpec.describe ITSM::EmailAddress do
  describe ".parse_all" do
    subject(:addresses) { described_class.parse_all(values) }

    let(:values) { ["Jane <Jane@Customer.example>", "support@example.com, help@example.com", nil] }

    it "returns the normalized addresses of every value" do
      expect(addresses).to eq(%w[jane@customer.example support@example.com help@example.com])
    end

    context "with a display name that looks like an address" do
      let(:values) { ["eve@example.com <alice@example.com>"] }

      it "returns only the actual address" do
        expect(addresses).to eq(%w[alice@example.com])
      end
    end

    context "with values that are not addresses" do
      let(:values) { ["undisclosed", "<>", "jane@", "colleague@customer.example"] }

      it "skips them" do
        expect(addresses).to eq(%w[colleague@customer.example])
      end
    end

    context "with the same address twice" do
      let(:values) { ["jane@customer.example", "JANE@customer.example"] }

      it "returns it once" do
        expect(addresses).to eq(%w[jane@customer.example])
      end
    end
  end
end
