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

RSpec.describe Workflow do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  shared_let(:global) { create(:named_workflow, name: "Standard flow") }
  shared_let(:owned) { create(:project_owned_workflow, project:, name: "Ours") }
  shared_let(:foreign) { create(:project_owned_workflow, project: other_project, name: "Theirs") }

  def under_test(scope) = scope.where(id: [global, owned, foreign]).to_a

  describe "scopes" do
    it "separates the global workflows from the owned ones" do
      expect(under_test(described_class.global)).to contain_exactly(global)
      expect(under_test(described_class.project_owned)).to contain_exactly(owned, foreign)
    end

    it "answers which project owns a workflow" do
      expect(under_test(described_class.owned_by(project))).to contain_exactly(owned)
      expect(under_test(described_class.owned_by(nil))).to contain_exactly(global)
    end

    it "offers a project the global workflows and its own" do
      expect(under_test(described_class.available_in(project))).to contain_exactly(global, owned)
      expect(under_test(described_class.available_in(nil))).to contain_exactly(global)
    end
  end

  describe "#project_specific?" do
    it "is true only for a workflow a project owns" do
      expect(owned).to be_project_specific
      expect(global).not_to be_project_specific
    end
  end

  describe "when the owning project is deleted" do
    let(:doomed) { create(:project) }

    it "takes its own workflows with it and leaves the global ones" do
      owned_id = create(:project_owned_workflow, project: doomed).id

      doomed.destroy!

      expect(described_class.where(id: owned_id)).to be_empty
      expect(described_class.where(id: global.id)).to be_present
    end

    it "removes a variant and the workflow that variant owns in one go" do
      variant = create(:project_owned_type_variant, project: doomed)
      variant_id = variant.id
      workflow_id = variant.workflow_id

      expect(described_class.find(workflow_id).project_id).to eq(doomed.id)

      expect { doomed.destroy! }.not_to raise_error

      expect(TypeVariant.where(id: variant_id)).to be_empty
      expect(described_class.where(id: workflow_id)).to be_empty
    end
  end
end
