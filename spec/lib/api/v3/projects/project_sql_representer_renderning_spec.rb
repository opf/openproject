#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require 'spec_helper'

describe ::API::V3::Projects::ProjectSqlRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:scope) do
    Project
      .where(id: project.id)
  end
  let(:project) do
    create(:project)
  end

  current_user do
    create(:user,
           member_in_project: project,
           member_with_permissions: [])
  end

  subject(:json) do
    ::API::V3::Utilities::SqlRepresenterWalker
      .new(scope,
           embed: {},
           select: { 'id' => {}, '_type' => {}, 'self' => {}, 'name' => {}, 'ancestors' => {} },
           current_user: current_user)
      .walk(described_class)
      .to_json
  end

  context 'without an ancestor' do
    it 'renders as expected' do
      expect(json)
        .to be_json_eql(
          {
            id: project.id,
            _type: "Project",
            name: project.name,
            _links: {
              ancestors: [],
              self: {
                href: api_v3_paths.project(project.id),
                title: project.name
              }
            }
          }.to_json)
    end
  end

  context 'with an ancestor' do
    let!(:parent) do
      create(:project).tap do |parent|
        project.parent = parent
        project.save
      end
    end

    let!(:grandparent) do
      create(:project).tap do |grandparent|
        parent.parent = grandparent
        parent.save
      end
    end

    it 'renders as expected' do
      expect(json)
        .to be_json_eql(
          {
            id: project.id,
            _type: "Project",
            name: project.name,
            _links: {
              ancestors: [
                {
                  href: api_v3_paths.project(grandparent.id),
                  title: grandparent.name
                },
                {
                  href: api_v3_paths.project(parent.id),
                  title: parent.name
                }
              ],
              self: {
                href: api_v3_paths.project(project.id),
                title: project.name
              }
            }
          }.to_json)
    end
  end
end
