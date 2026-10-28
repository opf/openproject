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

RSpec.describe DevelopmentData::CustomActionsSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let!(:admin) { create(:admin) }
  let(:on_hold) { create(:status, name: "On hold") }
  let(:high) { create(:priority_high) }
  let(:seed_data) do
    Source::SeedData.new(data_hash).tap do |data|
      data.store_reference(:default_status_on_hold, on_hold)
      data.store_reference(:default_priority_high, high)
    end
  end
  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      development_custom_actions:
        - name: Put on hold
          actions:
            status: :default_status_on_hold
        - name: Escalate
          actions:
            priority: :default_priority_high
            comment: Escalated.
        - name: Assign to me
          actions:
            assigned_to: current_user
    SEEDING_DATA_YAML
  end

  def actions_of(name)
    Automation.find_by!(name:).actions.to_h { |action| [action.key, action.values] }
  end

  it "creates a button automation for each custom action, with the referenced ids as values" do
    seeder.seed!

    expect(Automation.with_button_trigger.order(:name).map { [it.name, it.button_trigger.button_label] })
      .to eq([["Assign to me", "Assign to me"], ["Escalate", "Escalate"], ["Put on hold", "Put on hold"]])
    expect(actions_of("Put on hold")).to eq(status: [on_hold.id])
    expect(actions_of("Escalate")).to eq(priority: [high.id], comment: ["Escalated."])
    expect(actions_of("Assign to me")).to eq(assigned_to: ["current_user"])
  end

  it "seeds nothing a second time" do
    seeder.seed!

    expect { described_class.new(seed_data).seed! }.not_to change(Automation, :count)
  end
end
