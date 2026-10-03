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

RSpec.describe WorkPackageTypes::FormConfigurationGroups::MoveService do
  shared_let(:user) { create(:admin) }
  let(:form) { create(:form_configuration) }
  let!(:first) { create(:form_configuration_group, form_configuration: form, label: "First") }
  let!(:second) { create(:form_configuration_group, form_configuration: form, label: "Second") }
  let!(:third) { create(:form_configuration_group, form_configuration: form, label: "Third") }

  def move(group, prev_id, actor: user)
    described_class.new(user: actor, form_configuration: form, record: group).call(prev_id:)
  end

  def order = form.form_groups.reload.map(&:label)

  it "moves below the anchor" do
    expect(move(third, first.id.to_s)).to be_success
    expect(order).to eq(%w[First Third Second])
  end

  it "moves to the top for an empty anchor" do
    expect(move(third, "")).to be_success
    expect(order).to eq(%w[Third First Second])
  end

  it "takes the form's layout lock" do
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

    move(third, "")

    expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction).with(form, "layout")
  end

  it "places by the position read under the lock, not the one loaded before it" do
    stale = FormConfigurationGroup.find(first.id)
    FormConfigurationGroup.find(first.id).move_to_bottom

    expect(move(stale, second.id.to_s)).to be_success
    expect(order).to eq(%w[Second First Third])
  end

  it "moves the addressed group when two share a label" do
    twin = create(:form_configuration_group, form_configuration: form, label: "First")

    expect(move(twin, "")).to be_success
    expect(form.form_groups.reload.first).to eq(twin)
  end

  {
    "an unknown anchor" => ->(_) { "999999" },
    "itself as anchor" => ->(example) { example.third.id.to_s },
    "a malformed anchor" => ->(_) { "abc" },
    "a group of another form" => ->(example) { example.create(:form_configuration_group).id.to_s }
  }.each do |description, anchor|
    it "refuses #{description} without changing the order", :aggregate_failures do
      call = move(third, anchor.call(self))

      expect(call).to be_failure
      expect(call.message).to eq(I18n.t(:error_invalid_list_move_anchor))
      expect(order).to eq(%w[First Second Third])
    end
  end

  it "refuses a group that was deleted in the meantime", :aggregate_failures do
    stale = FormConfigurationGroup.find(third.id)
    third.destroy!
    call = move(stale, "")

    expect(call).to be_failure
    expect(call.message).to eq(I18n.t(:error_invalid_list_move_anchor))
    expect(order).to eq(%w[First Second])
  end

  it "refuses a user who is not an administrator", :aggregate_failures do
    call = move(third, "", actor: create(:user))

    expect(call).to be_failure
    expect(call.message).to eq(I18n.t("activerecord.errors.messages.error_unauthorized"))
    expect(order).to eq(%w[First Second Third])
  end

  it "reports an unexpected error as a failure instead of raising", :aggregate_failures do
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_raise(ActiveRecord::StatementInvalid, "boom")
    allow(OpenProject.logger).to receive(:error)

    call = move(third, "")

    expect(call).to be_failure
    expect(call.message).to eq(I18n.t("types.edit.form_configuration.move_failed"))
    expect(OpenProject.logger).to have_received(:error)
  end
end
