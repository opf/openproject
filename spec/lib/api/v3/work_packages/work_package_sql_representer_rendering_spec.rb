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

describe ::API::V3::WorkPackages::WorkPackageSqlRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  subject(:json) do
    ::API::V3::Utilities::SqlRepresenterWalker
      .new(scope,
           current_user: current_user,
           url_query: { select: select })
      .walk(described_class)
      .to_json
  end

  let(:scope) do
    WorkPackage
      .where(id: rendered_work_package.id)
  end

  let(:rendered_work_package) do
    create(:work_package,
           project: project,
           assigned_to: assignee)
  end
  let(:project) { create(:project) }
  let(:assignee) { create(:user) }

  let(:select) { { '*' => {} } }

  current_user do
    create(:user)
  end

  context 'when rendering all supported properties' do
    let(:expected) do
      {
        _type: "WorkPackage",
        id: rendered_work_package.id,
        subject: rendered_work_package.subject,
        _links: {
          self: {
            href: api_v3_paths.work_package(rendered_work_package.id),
            title: rendered_work_package.subject
          },
          project: {
            href: api_v3_paths.project(project.id),
            title: project.name
          },
          assignee: {
            href: api_v3_paths.user(assignee.id),
            title: assignee.name
          }
        }
      }
    end

    it 'renders as expected' do
      expect(json)
        .to be_json_eql(expected.to_json)
    end
  end

  describe 'assignee link' do
    let(:select) { { 'assignee' => {} } }

    context 'with a user' do
      let(:expected) do
        {
          _links: {
            assignee: {
              href: api_v3_paths.user(assignee.id),
              title: assignee.name
            }
          }
        }
      end

      it 'renders as expected' do
        expect(json)
          .to be_json_eql(expected.to_json)
      end
    end

    context 'with a group' do
      let(:assignee) { create(:group) }

      let(:expected) do
        {
          _links: {
            assignee: {
              href: api_v3_paths.group(assignee.id),
              title: assignee.name
            }
          }
        }
      end

      it 'renders as expected' do
        expect(json)
          .to be_json_eql(expected.to_json)
      end
    end

    context 'with a placeholder user' do
      let(:assignee) { create(:placeholder_user) }

      let(:expected) do
        {
          _links: {
            assignee: {
              href: api_v3_paths.placeholder_user(assignee.id),
              title: assignee.name
            }
          }
        }
      end

      it 'renders as expected' do
        expect(json)
          .to be_json_eql(expected.to_json)
      end
    end
  end
end
