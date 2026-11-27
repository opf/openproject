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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::Projects::Filters::IdFilter do
  it_behaves_like "basic query filter" do
    let(:model) { Project }
    let(:class_key) { :id }
    let(:type) { :list }
    let(:human_name) { "Project" }

    before do
      visible_scope = instance_double(ActiveRecord::Relation)
      allow(Project).to receive(:visible).and_return(visible_scope)
      allow(visible_scope).to receive(:pluck).with(:id).and_return([1234])
    end

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expect(instance.allowed_values).to eq([[1234, "1234"]])
      end
    end
  end

  it_behaves_like "list query filter" do
    let(:model) { Project }
    let(:attribute) { :id }
    let(:valid_values) { ["42"] }
  end

  describe "#project_ids" do
    let(:project) { create(:project, identifier: "current_id") }
    let(:other_project) { create(:project) }
    let(:instance) { described_class.create!(name: :id, operator: "=", values:) }

    before do
      allow(Project).to receive(:visible).and_return(Project.where(id: [project, other_project]))
    end

    context "with an identifier and an id" do
      let(:values) { ["CURRENT_ID", other_project.id.to_s] }

      it "resolves the identifier and keeps the values as given" do
        expect(instance.project_ids).to eq([project.id.to_s, other_project.id.to_s])
        expect(instance.values).to eq(["CURRENT_ID", other_project.id.to_s])
        expect(instance).to be_valid
      end
    end

    context "with the identifier of a project the user cannot see" do
      let(:values) { [create(:project).identifier] }

      it { expect(instance).not_to be_valid }
    end
  end
end
