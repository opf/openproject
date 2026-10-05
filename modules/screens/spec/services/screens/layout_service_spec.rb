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

RSpec.describe ::Screens::LayoutService do
  let(:screen) { create(:screen, screen_type: "create") }

  it "replaces the whole layout and normalises positions" do
    result = described_class.replace(screen, [
      { name: "General", items: [{ field_key: "subject" }, { field_key: "priority" }] },
      { name: "Details", items: [{ field_key: "description" }] }
    ])

    expect(result).to be_success
    screen.reload
    expect(screen.sections.pluck(:name)).to eq(%w[General Details])
    expect(screen.sections.first.items.pluck(:field_key)).to eq(%w[subject priority])
    expect(screen.sections.first.position).to eq(1)
    expect(screen.sections.second.position).to eq(2)
    expect(screen.sections.first.items.first.position).to eq(1)
  end

  it "rejects an unknown field" do
    result = described_class.replace(screen, [{ name: "General", items: [{ field_key: "does_not_exist" }] }])
    expect(result).to be_failure
    expect(result.errors.details[:base]).to include(error: :unknown_field)
  end

  it "rejects duplicate fields" do
    result = described_class.replace(screen, [
      { name: "General", items: [{ field_key: "subject" }, { field_key: "subject" }] }
    ])
    expect(result).to be_failure
    expect(result.errors.details[:base]).to include(error: :duplicate_field)
  end

  it "rejects too many items" do
    items = ::Screens::Fields.native_keys.first(3).map { |key| { field_key: key } }
    stub_const("Screen::MAX_ITEMS", 1)
    result = described_class.replace(screen, [{ name: "General", items: }])
    expect(result).to be_failure
    expect(result.errors.details[:base]).to include(error: :too_many_items)
  end
end
