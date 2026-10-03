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

RSpec.describe TypeSchemes::DefaultMigration do
  let!(:epic) { create(:type, name: "Epic", position: 1) }
  let!(:story) { create(:type, name: "Story", position: 2) }
  let!(:unused) { create(:type, name: "Unused", position: 3) }
  let!(:project_a) { create(:project, types: [story]) }
  let!(:project_b) { create(:project, types: [epic, story]) }

  it "rejects unknown modes" do
    expect { described_class.call(mode: "boom") }.to raise_error(ArgumentError)
  end

  it "dry_run reports the plan without writing" do
    plan = nil
    expect { plan = described_class.call(mode: "dry_run") }.not_to change(TypeScheme, :count)

    expect(plan.type_names).to eq %w[Epic Story]
    expect(plan.default_type_name).to eq "Epic"
    expect(plan.project_names).to include(project_a.name, project_b.name)
  end

  it "auto creates the default scheme and assigns every unassigned project" do
    described_class.call(mode: "auto")

    scheme = TypeScheme.find_by!(name: "Default Scheme")
    expect(scheme).to be_is_default
    expect(scheme.types).to eq [epic, story]
    expect(ProjectTypeScheme.where(scheme_id: scheme.id).pluck(:project_id)).to include(project_a.id, project_b.id)
  end

  it "manual creates the scheme only" do
    expect { described_class.call(mode: "manual") }
      .to change(TypeScheme, :count).by(1).and not_change(ProjectTypeScheme, :count)
  end

  it "is idempotent and leaves existing assignments alone" do
    other = create(:type_scheme, types: [story])
    TypeSchemes::SchemeService.assign(project_a, other)

    2.times { described_class.call(mode: "auto") }

    expect(TypeScheme.where(name: "Default Scheme").count).to eq 1
    expect(ProjectTypeScheme.find_by(project_id: project_a.id).scheme).to eq other
  end

  it "does not change types or work packages" do
    create(:work_package, project: project_a, type: story)

    expect { described_class.call(mode: "auto") }
      .to not_change(Type, :count).and not_change(WorkPackage, :count).and not_change { WorkPackage.pluck(:type_id) }
  end
end
