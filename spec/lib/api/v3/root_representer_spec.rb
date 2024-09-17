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

RSpec.describe API::V3::RootRepresenter do
  include API::V3::Utilities::PathHelper

  let(:user) { build_stubbed(:user) }
  let(:representer) { described_class.new({}, current_user: user) }
  let(:app_title) { "Foo Project" }
  let(:version) { "The version is over 9000!" }
  let(:permissions) { [:view_members] }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(*permissions, project: build_stubbed(:project)) # any project
    end
  end

  context "generation" do
    subject { representer.to_json }

    before do
      allow(Setting).to receive(:app_title).and_return app_title
      allow(OpenProject::VERSION).to receive(:to_semver).and_return version
    end

    describe "_links" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.root }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "configuration" }
        let(:href) { api_v3_paths.configuration }
      end

      describe "memberships" do
        context "if having the view_members permission in any project" do
          let(:permissions) { [:view_members] }

          it_behaves_like "has an untitled link" do
            let(:link) { "memberships" }
            let(:href) { api_v3_paths.memberships }
          end
        end

        context "if having the manage_members permission in any project" do
          let(:permissions) { [:manage_members] }

          it_behaves_like "has an untitled link" do
            let(:link) { "memberships" }
            let(:href) { api_v3_paths.memberships }
          end
        end

        context "if lacking permissions" do
          let(:permissions) { [] }

          it_behaves_like "has no link" do
            let(:link) { "members" }
          end
        end
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "priorities" }
        let(:href) { api_v3_paths.priorities }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "statuses" }
        let(:href) { api_v3_paths.statuses }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "types" }
        let(:href) { api_v3_paths.types }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "workPackages" }
        let(:href) { api_v3_paths.work_packages }
      end

      it_behaves_like "has a titled link" do
        let(:link) { "user" }
        let(:href) { api_v3_paths.user(user.id) }
        let(:title) { user.name }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "userPreferences" }
        let(:href) { api_v3_paths.user_preferences(user.id) }
      end

      context "anonymous user" do
        let(:representer) { described_class.new({}, current_user: User.anonymous) }

        it_behaves_like "has no link" do
          let(:link) { "user" }
        end

        it_behaves_like "has an untitled link" do
          let(:link) { "userPreferences" }
          let(:href) { api_v3_paths.user_preferences(User.anonymous.id) }
        end
      end
    end

    context "attributes" do
      describe "_type" do
        it 'is "Root"' do
          expect(subject)
            .to be_json_eql("Root".to_json)
            .at_path("_type")
        end
      end

      describe "coreVersion" do
        context "for a non admin user" do
          it "has no coreVersion property" do
            expect(subject)
              .not_to have_json_path("coreVersion")
          end
        end

        context "for an admin user" do
          let(:user) { build_stubbed(:admin) }

          it "indicates the OpenProject version number" do
            expect(subject)
              .to be_json_eql(version.to_json)
              .at_path("coreVersion")
          end
        end
      end

      describe "instanceName" do
        it "shows the name of the instance" do
          expect(subject)
            .to be_json_eql(app_title.to_json)
            .at_path("instanceName")
        end
      end
    end
  end
end
