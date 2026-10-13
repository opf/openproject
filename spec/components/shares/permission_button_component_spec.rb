# frozen_string_literal: true

# -- copyright
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
# ++
require "spec_helper"

RSpec.describe Shares::PermissionButtonComponent, type: :component do
  describe "#wrapper_uniq_by" do
    subject(:component) { described_class.new(share:, strategy: nil, test_selector: "op-share-dialog-invite-role") }

    context "with a persisted share" do
      let(:share) { build_stubbed(:member) }

      it "uses the share id" do
        expect(component.wrapper_uniq_by).to eq(share.id)
      end
    end

    context "with a new share" do
      let(:share) { Member.new }

      it "falls back to the test selector" do
        expect(component.wrapper_uniq_by).to eq("op-share-dialog-invite-role")
      end
    end
  end
end
