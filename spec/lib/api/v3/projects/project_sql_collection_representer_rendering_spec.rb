#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe API::V3::Projects::ProjectSqlCollectionRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:json) do
    API::V3::Utilities::SqlRepresenterWalker
      .new(scope,
           current_user:,
           self_path: "some_path",
           url_query: { offset: 1, pageSize: 5, select: })
      .walk(described_class)
      .to_json
  end

  let(:scope) do
    Project
      .where(id: project.id)
  end

  let(:project) do
    create(:project)
  end

  let(:role) { create(:project_role) }

  let(:select) do
    { "*" => {}, "elements" => { "*" => {} } }
  end

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  context "when rendering everything" do
    let(:expected) do
      {
        _type: "Collection",
        pageSize: 5,
        total: 1,
        count: 1,
        offset: 1,
        _embedded: {
          elements: [
            {
              id: project.id,
              _type: "Project",
              name: project.name,
              identifier: project.identifier,
              active: true,
              public: false,
              _links: {
                ancestors: [],
                self: {
                  href: api_v3_paths.project(project.id),
                  title: project.name
                }
              }
            }
          ]
        },
        _links: {
          self: {
            href: "some_path?offset=1&pageSize=5&select=%2A%2Celements%2F%2A"
          },
          changeSize: {
            href: "some_path?offset=1&pageSize=%7Bsize%7D&select=%2A%2Celements%2F%2A",
            templated: true
          },
          jumpTo: {
            href: "some_path?offset=%7Boffset%7D&pageSize=5&select=%2A%2Celements%2F%2A",
            templated: true
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(expected)
    end
  end

  context "when rendering only collection attributes" do
    let(:select) do
      { "*" => {} }
    end

    let(:expected) do
      {
        _type: "Collection",
        pageSize: 5,
        total: 1,
        count: 1,
        offset: 1,
        _links: {
          self: {
            href: "some_path?offset=1&pageSize=5&select=%2A"
          },
          changeSize: {
            href: "some_path?offset=1&pageSize=%7Bsize%7D&select=%2A",
            templated: true
          },
          jumpTo: {
            href: "some_path?offset=%7Boffset%7D&pageSize=5&select=%2A",
            templated: true
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(expected)
    end
  end

  context "when not having a project to render" do
    let(:scope) do
      Project.none
    end

    let(:select) do
      { "*" => {} }
    end

    let(:expected) do
      {
        _type: "Collection",
        pageSize: 5,
        total: 0,
        count: 0,
        offset: 1,
        _links: {
          self: {
            href: "some_path?offset=1&pageSize=5&select=%2A"
          },
          changeSize: {
            href: "some_path?offset=1&pageSize=%7Bsize%7D&select=%2A",
            templated: true
          },
          jumpTo: {
            href: "some_path?offset=%7Boffset%7D&pageSize=5&select=%2A",
            templated: true
          }
        }
      }.to_json
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(expected)
    end
  end
end
