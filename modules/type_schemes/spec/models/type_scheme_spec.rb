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

RSpec.describe TypeScheme do
  let(:epic)  { create(:type, name: "Epic") }
  let(:story) { create(:type, name: "Story") }

  def build_scheme(items, **attrs)
    described_class.new(name: "Dev", **attrs).tap do |scheme|
      items.each_with_index do |(type, default), i|
        scheme.items.build(type:, position: i + 1, is_default: default)
      end
    end
  end

  it "requires a name" do
    scheme = build_scheme([[epic, true]], name: nil)
    expect(scheme).not_to be_valid
    expect(scheme.errors[:name]).to be_present
  end

  it "requires a unique name" do
    create(:type_scheme, name: "Dev")
    scheme = build_scheme([[epic, true]])
    expect(scheme).not_to be_valid
    expect(scheme.errors[:name]).to be_present
  end

  it "rejects duplicate types" do
    scheme = build_scheme([[epic, true], [epic, false]])
    expect(scheme).not_to be_valid
    expect(scheme.errors[:items]).to include(a_string_matching(/same type/))
  end

  it "requires exactly one default item when active" do
    expect(build_scheme([[epic, false], [story, false]])).not_to be_valid
    expect(build_scheme([[epic, true], [story, true]])).not_to be_valid
    expect(build_scheme([[epic, false], [story, true]])).to be_valid
  end

  it "skips the default item rule when inactive" do
    expect(build_scheme([[epic, false]], active: false)).to be_valid
  end

  it "exposes ordered types and default type" do
    scheme = build_scheme([[epic, false], [story, true]]).tap(&:save!)
    expect(scheme.types).to eq([epic, story])
    expect(scheme.default_type).to eq(story)
  end

  it "allows only one default scheme" do
    create(:type_scheme, is_default: true)
    expect(build(:type_scheme, is_default: true)).not_to be_valid
  end

  it "cannot be destroyed" do
    scheme = create(:type_scheme)
    expect(scheme.destroy).to be(false)
    expect(described_class.exists?(scheme.id)).to be(true)
    expect(scheme.errors.symbols_for(:base)).to include(:cannot_be_deleted)
  end

  it "keeps the default scheme active" do
    scheme = create(:type_scheme, is_default: true)
    scheme.active = false
    expect(scheme).not_to be_valid
    expect(scheme.errors.symbols_for(:active)).to include(:default_scheme_required)
  end

  describe "DB constraints" do
    it "allows only one default scheme" do
      create(:type_scheme, is_default: true)
      other = build(:type_scheme, is_default: true)
      expect { other.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows only one default item per scheme" do
      scheme = create(:type_scheme)
      item = scheme.items.build(type: create(:type), position: 2, is_default: true)
      expect { item.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
