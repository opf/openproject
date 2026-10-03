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

RSpec.describe WorkPackageTypes::FormConfigurationRows::MoveService do
  shared_let(:user) { create(:admin) }
  let(:form) { create(:form_configuration) }
  let!(:details) { create(:form_configuration_group, form_configuration: form, label: "Details") }
  let!(:other) { create(:form_configuration_group, form_configuration: form, label: "Other") }
  let!(:empty) { create(:form_configuration_group, form_configuration: form, label: "Empty") }
  let!(:assignee) { membership("assignee", details, 1) }
  let!(:priority) { membership("priority", details, 2) }
  let!(:date) { membership("date", details, 3) }
  let!(:category) { membership("category", other, 1) }
  let!(:responsible) { membership("responsible") }
  let(:initial_layout) do
    { "Details" => %w[assignee priority date], "Other" => %w[category], "Empty" => [], "inactive" => %w[responsible] }
  end

  def membership(key, group = nil, position = nil)
    create(:form_configuration_attribute, form_configuration: form, group:, position:, attribute_key: key)
  end

  def move(record, **params)
    described_class.new(user:, form_configuration: form, record:).call(**params)
  end

  def into(group, prev_id) = { list_type: "attribute", list_id: group.id.to_s, prev_id: }

  def layout
    form.form_groups.reload.to_h { [it.label, it.members.reload.map(&:key)] }
        .merge("inactive" => form.form_attributes.inactive.map(&:key).sort)
  end

  def positions(group) = group.members.reload.map(&:position)

  it "starts from the expected layout" do
    expect(layout).to eq(initial_layout)
  end

  it "moves within its group below the anchor" do
    expect(move(date, **into(details, assignee.id.to_s))).to be_success
    expect(layout["Details"]).to eq(%w[assignee date priority])
  end

  it "moves to the top of its group for an empty anchor" do
    expect(move(date, **into(details, ""))).to be_success
    expect(layout["Details"]).to eq(%w[date assignee priority])
  end

  it "moves into another group below the anchor, keeping both lists contiguous", :aggregate_failures do
    id = priority.id

    expect(move(priority, **into(other, category.id.to_s))).to be_success

    expect(layout).to include("Details" => %w[assignee date], "Other" => %w[category priority])
    expect(positions(details)).to eq([1, 2])
    expect(positions(other)).to eq([1, 2])
    expect(FormConfigurationAttribute.find(id)).to have_attributes(form_configuration_group_id: other.id)
  end

  it "moves into an empty group" do
    expect(move(priority, **into(empty, ""))).to be_success
    expect(layout).to include("Details" => %w[assignee date], "Empty" => %w[priority])
  end

  it "activates an inactive attribute, keeping its record", :aggregate_failures do
    id = responsible.id

    expect(move(responsible, **into(details, ""))).to be_success

    expect(layout).to include("Details" => %w[responsible assignee priority date], "inactive" => [])
    expect(FormConfigurationAttribute.find(id)).to be_active
  end

  it "deactivates into the inactive list, ignoring the anchor", :aggregate_failures do
    id = priority.id

    expect(move(priority, list_type: "inactive_attribute", prev_id: responsible.id.to_s)).to be_success

    expect(layout).to include("Details" => %w[assignee date], "inactive" => %w[priority responsible])
    expect(positions(details)).to eq([1, 2])
    expect(FormConfigurationAttribute.find(id)).not_to be_active
  end

  it "accepts an already inactive attribute dropped in the inactive list" do
    expect(move(responsible, list_type: "inactive_attribute")).to be_success
    expect(layout).to eq(initial_layout)
  end

  it "places by the state read under the lock, not the one loaded before it" do
    stale = FormConfigurationAttribute.find(assignee.id)
    FormConfigurationAttribute.find(assignee.id).move_to_bottom

    expect(move(stale, **into(details, priority.id.to_s))).to be_success
    expect(layout["Details"]).to eq(%w[priority assignee date])
  end

  it "keeps a hidden membership in its relative place" do
    hidden = membership("no_longer_offered", details, 4)

    expect(move(date, **into(details, ""))).to be_success

    expect(details.members.reload.map(&:key)).to eq(%w[date assignee priority no_longer_offered])
    expect(hidden.reload.position).to eq(4)
  end

  it "takes the form's layout lock" do
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

    move(date, **into(details, ""))

    expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction).with(form, "layout")
  end

  describe "refusals" do
    let(:foreign_group) { create(:form_configuration_group, label: "Elsewhere") }
    let!(:query_group) { create(:form_configuration_group, :query, form_configuration: form, label: "Table") }
    let(:initial_layout) { super().merge("Table" => []) }

    {
      "an unknown list type" => ->(e) { { list_type: "section", list_id: e.other.id.to_s, prev_id: "" } },
      "a missing destination" => ->(_) { { list_type: "attribute", prev_id: "" } },
      "a malformed destination" => ->(e) { { list_type: "attribute", list_id: "0#{e.other.id}", prev_id: "" } },
      "a group of another form" => ->(e) { { list_type: "attribute", list_id: e.foreign_group.id.to_s, prev_id: "" } },
      "a query group" => ->(e) { { list_type: "attribute", list_id: e.query_group.id.to_s, prev_id: "" } },
      "a missing anchor key" => ->(e) { { list_type: "attribute", list_id: e.other.id.to_s } },
      "an anchor from another group" => ->(e) { e.into(e.other, e.assignee.id.to_s) },
      "an unknown anchor" => ->(e) { e.into(e.other, "999999") },
      "itself as anchor" => ->(e) { e.into(e.details, e.priority.id.to_s) },
      "a malformed anchor" => ->(e) { e.into(e.other, "abc") },
      "a destination id for the inactive list" => ->(e) { { list_type: "inactive_attribute", list_id: e.other.id.to_s } }
    }.each do |description, params|
      it "refuses #{description} without changing the layout", :aggregate_failures do
        call = move(priority, **params.call(self))

        expect(call).to be_failure
        expect(call.message).to eq(I18n.t(:error_invalid_list_move_anchor))
        expect(layout).to eq(initial_layout)
      end
    end

    it "refuses to activate an attribute the form no longer offers", :aggregate_failures do
      gone = membership("no_longer_offered")
      call = move(gone, **into(details, ""))

      expect(call).to be_failure
      expect(call.message).to eq(I18n.t(:error_invalid_list_move_anchor))
      expect(layout["Details"]).to eq(%w[assignee priority date])
      expect(layout["inactive"]).to include("no_longer_offered")
    end

    it "refuses a membership that was deleted in the meantime", :aggregate_failures do
      stale = FormConfigurationAttribute.find(priority.id)
      priority.destroy!
      call = move(stale, **into(other, ""))

      expect(call).to be_failure
      expect(call.message).to eq(I18n.t(:error_invalid_list_move_anchor))
    end
  end
end
