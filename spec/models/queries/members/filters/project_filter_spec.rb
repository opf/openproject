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

RSpec.describe Queries::Members::Filters::ProjectFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :project_id }
    let(:type) { :list_optional }
  end

  it_behaves_like "list_optional query filter" do
    let(:attribute) { :project_id }
    let(:model) { Member }
    let(:valid_values) { ["1"] }
  end

  describe "the global sentinel" do
    let(:instance) do
      described_class.create!(name: :project_id, operator: "=", values:)
    end

    context "when selected on its own" do
      let(:values) { [described_class::GLOBAL_VALUE] }

      it { expect(instance).to be_valid }

      it "matches memberships without a project" do
        expect(instance.where).to eq("members.project_id IS NULL")
      end
    end

    context "when selected alongside projects" do
      let(:values) { [described_class::GLOBAL_VALUE, "1", "2"] }

      it { expect(instance).to be_valid }

      it "matches those projects as well as the global memberships" do
        expect(instance.where).to eq("members.project_id IS NULL OR members.project_id IN ('1','2')")
      end
    end

    context "when combined with a non numeric project id" do
      let(:values) { [described_class::GLOBAL_VALUE, "not-an-id"] }

      it { expect(instance).not_to be_valid }
    end
  end
end
