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

  it "moves to the top for a blank anchor" do
    expect(section_c.move_after_anchor("", scope:)).to be(true)
    expect(order).to eq(%w[C A B])
  end

  it "moves downward directly below the anchor" do
    expect(section_a.move_after_anchor(section_b.id.to_s, scope:)).to be(true)
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
end
