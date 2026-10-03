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

RSpec.describe OpenProject::TypeSchemes::ProjectCreatedListener do
  let!(:story) { create(:type, name: "Story") }
  let(:project) { create(:project, types: [story]) }

  it "assigns the default scheme to a new project" do
    scheme = create(:type_scheme, types: [story], is_default: true)

    described_class.call(project:)

    expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to eq scheme
  end

  it "creates the default scheme when none exists yet" do
    described_class.call(project:)

    assigned = ProjectTypeScheme.find_by!(project_id: project.id).scheme
    expect(assigned).to be_is_default
    expect(assigned.types).to include(story)
  end

  it "does not touch a project that already has a scheme" do
    create(:type_scheme, types: [story], is_default: true)
    other = create(:type_scheme, types: [story])
    TypeSchemes::SchemeService.assign(project, other)

    described_class.call(project:)

    expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to eq other
  end

  it "is triggered by the PROJECT_CREATED event" do
    scheme = create(:type_scheme, types: [story], is_default: true)

    OpenProject::Notifications.send(OpenProject::Events::PROJECT_CREATED, project:)

    expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to eq scheme
  end
end
