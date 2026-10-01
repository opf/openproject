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

require "spec_helper"

RSpec.describe Lists::MoveAfterAnchor do
  shared_let(:section_a) { create(:project_custom_field_section, name: "A") }
  shared_let(:section_b) { create(:project_custom_field_section, name: "B") }
  shared_let(:section_c) { create(:project_custom_field_section, name: "C") }

  let(:scope) { ProjectCustomFieldSection.all }

  def order = scope.reload.order(:position).pluck(:name)

  it "moves to the top for an empty anchor" do
    expect(section_c.move_after_anchor("", scope:)).to be(true)
    expect(order).to eq(%w[C A B])
  end

  it "moves to the top for a nil anchor" do
    expect(section_c.move_after_anchor(nil, scope:)).to be(true)
    expect(order).to eq(%w[C A B])
  end

  it "moves downward directly below the anchor" do
    expect(section_a.move_after_anchor(section_b.id.to_s, scope:)).to be(true)
    expect(order).to eq(%w[B A C])
  end

  it "accepts an Integer anchor" do
    expect(section_a.move_after_anchor(section_b.id, scope:)).to be(true)
    expect(order).to eq(%w[B A C])
  end

  it "moves upward directly below the anchor" do
    expect(section_c.move_after_anchor(section_a.id.to_s, scope:)).to be(true)
    expect(order).to eq(%w[A C B])
  end

  it "rejects an unknown anchor without mutating" do
    expect(section_a.move_after_anchor("999999", scope:)).to be(false)
    expect(order).to eq(%w[A B C])
  end

  it "rejects a self anchor without mutating" do
    expect(section_b.move_after_anchor(section_b.id.to_s, scope:)).to be(false)
    expect(order).to eq(%w[A B C])
  end

  it "rejects an out-of-scope anchor without mutating" do
    foreign = create(:user_custom_field_section)
    expect(section_a.move_after_anchor(foreign.id.to_s, scope:)).to be(false)
    expect(order).to eq(%w[A B C])
  end

  describe "malformed anchors" do
    {
      "false" => -> { false },
      "true" => -> { true },
      "a Float" => -> { section_b.id + 0.5 },
      "zero" => -> { 0 },
      "a zero string" => -> { "0" },
      "a negative Integer" => -> { -1 },
      "a negative string" => -> { "-1" },
      "a signed id" => -> { "+#{section_b.id}" },
      "a zero-padded id" => -> { "0#{section_b.id}" },
      "a decimal id string" => -> { "#{section_b.id}.0" },
      "a suffixed id" => -> { "#{section_b.id}junk" },
      "a padded id" => -> { " #{section_b.id}" },
      "an Array" => -> { [section_b.id] },
      "a Hash" => -> { { id: section_b.id } }
    }.each do |description, anchor_builder|
      it "rejects #{description} without mutating" do
        expect(section_c.move_after_anchor(instance_exec(&anchor_builder), scope:)).to be(false)
        expect(order).to eq(%w[A B C])
      end
    end
  end
end
