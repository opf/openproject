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

RSpec.describe Queries::Sprints::Filters::StatusFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :status }
    let(:human_name) { Sprint.human_attribute_name(:status) }
    let(:type) { :list }
    let(:model) { Sprint }

    describe "#allowed_values" do
      it "lists all statuses" do
        expect(instance.allowed_values.map(&:last)).to contain_exactly("in_planning", "active", "completed")
      end
    end
  end

  describe "#apply_to" do
    shared_let(:in_planning_sprint) { create(:sprint) }
    shared_let(:active_sprint) { create(:sprint, :active) }
    shared_let(:completed_sprint) { create(:sprint, :completed) }

    let(:scope) { Sprint.all }

    subject(:filtered) do
      described_class.create!(operator:, values:).apply_to(scope)
    end

    context "with = and a single status" do
      let(:operator) { "=" }
      let(:values) { %w[active] }

      it { is_expected.to contain_exactly(active_sprint) }
    end

    context "with = and several statuses" do
      let(:operator) { "=" }
      let(:values) { %w[in_planning completed] }

      it { is_expected.to contain_exactly(in_planning_sprint, completed_sprint) }
    end

    context "with ! and a single status" do
      let(:operator) { "!" }
      let(:values) { %w[completed] }

      it { is_expected.to contain_exactly(in_planning_sprint, active_sprint) }
    end

    context "with ! and several statuses" do
      let(:operator) { "!" }
      let(:values) { %w[in_planning active] }

      it { is_expected.to contain_exactly(completed_sprint) }
    end

    context "when the scope already has conditions" do
      let(:operator) { "!" }
      let(:values) { %w[completed] }
      let(:scope) { Sprint.where(id: [active_sprint.id, completed_sprint.id]) }

      it { is_expected.to contain_exactly(active_sprint) }
    end
  end
end
