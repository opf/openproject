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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Screens::Repair do
  let(:screen) { create(:screen) }
  let(:section) { create(:screen_section, screen:, position: 7) }

  it "reports orphan custom field items without changing them in dry run" do
    item = create(:screen_item, screen:, section:, field_key: "custom_field_999999")

    report = described_class.call(dry_run: true)
    expect(report.orphan_items).to be >= 1
    expect(ScreenItem.exists?(item.id)).to be(true)
  end

  it "removes orphan custom field items and normalises positions when applied" do
    create(:screen_item, screen:, section:, field_key: "custom_field_999999")
    live = create(:screen_item, screen:, section:, field_key: "subject")

    described_class.call(dry_run: false)
    expect(ScreenItem.exists?(live.id)).to be(true)
    expect(screen.reload.sections.first.position).to eq(1)
    expect(screen.sections.first.items.first.position).to eq(1)
  end

  it "is idempotent" do
    described_class.call(dry_run: false)
    expect { described_class.call(dry_run: false) }.not_to change(ScreenItem, :count)
  end
end
