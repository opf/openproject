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

RSpec.describe API::V3::Projects::ProjectSqlRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:json) do
    API::V3::Utilities::SqlRepresenterWalker
      .new(scope,
           current_user:,
           url_query: { select: })
      .walk(described_class)
      .to_json
  end

  let(:scope) do
    Project
      .where(id: project.id)
  end
  let(:role) { create(:project_role) }
  let(:select) { { "*" => {} } }

  shared_let(:portfolio, reload: true) do
    create(:portfolio)
  end
  shared_let(:program, reload: true) do
    create(:program)
  end
  shared_let(:project, reload: true) do
    create(:project)
  end

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  context "when rendering all supported properties of a project" do
    it "renders as expected" do
      expect(json)
        .to be_json_eql(
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
          }.to_json
        )
    end
  end

  context "when rendering all supported properties of a program" do
    let(:scope) do
      Project
        .where(id: program.id)
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(
          {
            id: program.id,
            _type: "Program",
            name: program.name,
            identifier: program.identifier,
            active: true,
            public: false,
            _links: {
              ancestors: [],
              self: {
                href: api_v3_paths.program(program.id),
                title: program.name
              }
            }
          }.to_json
        )
    end
  end

  context "when rendering all supported properties of a portfolio" do
    let(:scope) do
      Project
        .where(id: portfolio.id)
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(
          {
            id: portfolio.id,
            _type: "Portfolio",
            name: portfolio.name,
            identifier: portfolio.identifier,
            active: true,
            public: false,
            _links: {
              ancestors: [],
              self: {
                href: api_v3_paths.portfolio(portfolio.id),
                title: portfolio.name
              }
            }
          }.to_json
        )
    end
  end

  context "with an ancestor" do
    let!(:elder) do
      create(:portfolio, members: { current_user => role })
    end

    let!(:grandparent) do
      create(:program, members: { current_user => role }, parent: elder)
    end

    let!(:parent) do
      create(:project, members: { current_user => role }, parent: grandparent) do |parent|
        project.parent = parent
        project.save
      end
    end

    let(:select) { { "ancestors" => {} } }

    it "renders as expected" do
      expect(json)
        .to be_json_eql(
          {
            _links: {
              ancestors: [
                {
                  href: api_v3_paths.portfolio(elder.id),
                  title: elder.name
                },
                {
                  href: api_v3_paths.program(grandparent.id),
                  title: grandparent.name
                },
                {
                  href: api_v3_paths.project(parent.id),
                  title: parent.name
                }
              ]
            }
          }.to_json
        )
    end
  end

  context "with an ancestor the user does not have permission to see" do
    let!(:parent) do
      create(:project).tap do |parent|
        project.parent = parent
        project.save
      end
    end

    let!(:grandparent) do
      create(:project, members: { current_user => role }).tap do |grandparent|
        parent.parent = grandparent
        parent.save
      end
    end

    let(:select) { { "ancestors" => {} } }

    it "renders as expected" do
      expect(json)
        .to be_json_eql(
          {
            _links: {
              ancestors: [
                {
                  href: api_v3_paths.project(grandparent.id),
                  title: grandparent.name
                },
                {
                  href: API::V3::URN_UNDISCLOSED,
                  title: I18n.t(:"api_v3.undisclosed.ancestor")
                }
              ]
            }
          }.to_json
        )
    end

    context "with relative url root", with_config: { rails_relative_url_root: "/foobar" } do
      it "renders correctly" do
        expect(json)
          .to be_json_eql(
            {
              _links: {
                ancestors: [
                  {
                    href: "/foobar/api/v3/projects/#{grandparent.id}",
                    title: grandparent.name
                  },
                  {
                    href: API::V3::URN_UNDISCLOSED,
                    title: I18n.t(:"api_v3.undisclosed.ancestor")
                  }
                ]
              }
            }.to_json
          )
      end
    end

    context "when in a foreign language with single quotes in the translation hint text" do
      before do
        I18n.locale = :fr
      end

      it "renders as expected" do
        expect(json)
          .to be_json_eql(
            {
              _links: {
                ancestors: [
                  {
                    href: api_v3_paths.project(grandparent.id),
                    title: grandparent.name
                  },
                  {
                    href: API::V3::URN_UNDISCLOSED,
                    title: I18n.t(:"api_v3.undisclosed.ancestor")
                  }
                ]
              }
            }.to_json
          )
      end
    end
  end

  context "with an archived ancestor but with the user being admin" do
    let!(:parent) do
      create(:project, active: false).tap do |parent|
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

    let(:select) { { "ancestors" => {} } }

    current_user do
      create(:admin)
    end

    it "renders as expected" do
      expect(json)
        .to be_json_eql(
          {
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
              ]
            }
          }.to_json
        )
    end
  end
end
