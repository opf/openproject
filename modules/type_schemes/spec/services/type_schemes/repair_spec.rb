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

RSpec.describe TypeSchemes::Repair do
  let!(:epic) { create(:type, name: "Epic", position: 1) }
  let!(:task) { create(:type, name: "Task", position: 2) }
  let!(:bug) { create(:type, name: "Bug", position: 3) }
  let!(:project) { create(:project, types: [task]) }

  def default_scheme = TypeScheme.find_by!(is_default: true)

  context "when everything is consistent" do
    before { TypeSchemes::DefaultScheme.ensure! && TypeSchemes::SchemeService.assign_default(project) }

    it "reports nothing and changes nothing" do
      report = nil
      expect { report = described_class.call(dry_run: false) }
        .to not_change(TypeScheme, :count).and not_change(TypeSchemeItem, :count).and not_change(ProjectTypeScheme, :count)

      expect(report).not_to be_changed
    end
  end

  context "when the default scheme is missing" do
    it "creates it with Task as default type and assigns the project" do
      described_class.call(dry_run: false)

      expect(default_scheme).to be_active
      expect(default_scheme.default_type).to eq task
      expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to eq default_scheme
    end

    it "writes nothing in dry run" do
      report = nil
      expect { report = described_class.call(dry_run: true) }
        .to not_change(TypeScheme, :count).and not_change(ProjectTypeScheme, :count)

      expect(report).to be_changed
    end

    it "does nothing without types" do
      WorkPackage.delete_all
      Type.destroy_all

      expect { described_class.call(dry_run: false) }.not_to change(TypeScheme, :count)
    end
  end

  context "when the default type was removed by a cascading type deletion" do
    before { TypeSchemes::DefaultScheme.ensure! }

    it "promotes Task again after the Task type was deleted and recreated" do
      task.destroy
      recreated = create(:type, name: "Task", position: 2)

      described_class.call(dry_run: false)

      expect(default_scheme.reload.default_type).to eq recreated
      expect(default_scheme).to be_valid
    end

    it "promotes the first non-milestone type when no Task exists" do
      task.destroy

      described_class.call(dry_run: false)

      expect(default_scheme.reload.default_type).to eq epic
    end

    it "repairs a custom scheme that lost its default item" do
      custom = create(:type_scheme, types: [bug, epic])
      custom.default_item.type.destroy
      expect(custom.reload).not_to be_valid

      described_class.call(dry_run: false)

      expect(custom.reload).to be_valid
    end

    it "only reports in dry run" do
      task.destroy

      expect { described_class.call(dry_run: true) }.not_to change { TypeSchemeItem.where(is_default: true).count }
    end
  end

  context "when the default scheme lost every item" do
    before do
      TypeSchemes::DefaultScheme.ensure!
      TypeSchemeItem.where(scheme_id: default_scheme.id).delete_all
    end

    it "refills it from all types with a default type" do
      described_class.call(dry_run: false)

      expect(default_scheme.reload.types).to contain_exactly(epic, task, bug)
      expect(default_scheme.default_type).to eq task
    end
  end

  context "when types are missing from the default scheme" do
    before { TypeSchemes::DefaultScheme.ensure! }

    it "appends them without making them default" do
      TypeSchemeItem.where(scheme_id: default_scheme.id, type_id: bug.id).delete_all

      described_class.call(dry_run: false)

      expect(default_scheme.reload.types).to include(bug)
      expect(default_scheme.default_type).to eq task
    end
  end

  context "when projects have no usable scheme" do
    let!(:inactive) { create(:type_scheme, types: [bug]) }
    let!(:other_project) { create(:project, types: [bug]) }

    before do
      TypeSchemes::DefaultScheme.ensure!
      TypeSchemes::SchemeService.assign(other_project, inactive)
      inactive.update_columns(active: false)
    end

    it "assigns unassigned projects and moves projects off inactive schemes" do
      described_class.call(dry_run: false)

      expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to eq default_scheme
      expect(ProjectTypeScheme.find_by(project_id: other_project.id).scheme).to eq default_scheme
    end

    it "is idempotent" do
      described_class.call(dry_run: false)

      expect(described_class.call(dry_run: false)).not_to be_changed
    end
  end

  context "when an inactive scheme holds the default flag" do
    let!(:scheme) { create(:type_scheme, types: [task], is_default: true) }

    before { scheme.update_columns(active: false) }

    it "re-activates it instead of creating a second default scheme" do
      expect { described_class.call(dry_run: false) }.not_to change(TypeScheme, :count)

      expect(scheme.reload).to be_active
    end
  end

  it "never touches types or work packages" do
    create(:work_package, project:, type: bug)

    expect { described_class.call(dry_run: false) }
      .to not_change(Type, :count).and not_change(WorkPackage, :count).and not_change { WorkPackage.pluck(:type_id) }
  end
end
