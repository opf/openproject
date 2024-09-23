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

RSpec.describe Project, "allowed to" do
  let(:user) { build(:user) }
  let(:anonymous) { build(:anonymous) }
  let(:admin) { build(:admin) }

  let(:private_project) do
    build(:project,
          public: false,
          active: project_status)
  end
  let(:public_project) do
    build(:project,
          public: true,
          active: project_status)
  end
  let(:project_status) { true }

  let(:role) do
    build(:project_role,
          permissions:)
  end
  let(:anonymous_role) do
    build(:anonymous_role,
          permissions: anonymous_permissions)
  end
  let(:non_member_role) do
    build(:non_member,
          permissions: non_member_permissions)
  end
  let(:permissions) { [action] }
  let(:anonymous_permissions) { [action] }
  let(:non_member_permissions) { [action] }
  let(:action) { :view_work_packages }
  let(:public_action) { :view_news }
  let(:public_non_module_action) { :view_project }
  let(:non_module_action) { :edit_project }
  let(:member) do
    build(:member,
          user:,
          roles: [role],
          project:)
  end

  shared_examples_for "includes the project" do
    it "includes the project" do
      expect(described_class.allowed_to(user, action)).to contain_exactly(project)
    end
  end

  shared_examples_for "is empty" do
    it "is empty" do
      expect(described_class.allowed_to(user, action)).to be_empty
    end
  end

  shared_examples_for "member based allowed to check" do
    before do
      project.save!
      user.save!
    end

    context "with the user being member " \
            "with the role having the permission" do
      before do
        non_member_role.save!
        member.save!
      end

      it_behaves_like "includes the project"
    end

    context "with the user being member " \
            "with the role having the permission " \
            "without the project being active" do
      let(:project_status) { false }

      before do
        member.save!
      end

      it_behaves_like "is empty"
    end

    context "with the user being member " \
            "without the role having the permission" do
      let(:permissions) { [] }

      before do
        member.save!
      end

      it_behaves_like "is empty"
    end

    context "without the user being member " \
            "with the role having the permission" do
      it_behaves_like "is empty"
    end

    context "with the user being member " \
            "with the role having the permission " \
            "without the associated module being active" do
      before do
        member.save!
        project.enabled_modules = []
      end

      it_behaves_like "is empty"
    end

    context "with the user being member " \
            "with the permission being public" do
      before do
        member.save!
      end

      it "includes the project" do
        expect(described_class.allowed_to(user, public_action)).to contain_exactly(project)
      end
    end

    context "with the user being member " \
            "with the permission being public " \
            "without the associated module being active" do
      before do
        member.save!
        project.enabled_modules = []
      end

      it "is empty" do
        expect(described_class.allowed_to(user, public_action)).to be_empty
      end
    end

    context "with the user being member " \
            "with the permission being public and not module bound " \
            "with no module being active" do
      before do
        member.save!
        project.enabled_modules = []
      end

      it "includes the project" do
        expect(described_class.allowed_to(user, public_non_module_action)).to contain_exactly(project)
      end
    end

    context "with the user being member " \
            "without the permission being module bound " \
            "with the role having the permission " \
            "with no module active" do
      let(:permissions) { [non_module_action] }

      before do
        member.save!
      end

      it "includes the project" do
        expect(described_class.allowed_to(user, non_module_action)).to contain_exactly(project)
      end
    end

    context "with the user being member " \
            "without the permission being module bound " \
            "without the role having the permission " \
            "with no module active" do
      let(:permissions) { [] }

      before do
        member.save!
      end

      it "is empty" do
        expect(described_class.allowed_to(user, non_module_action)).to be_empty
      end
    end
  end

  shared_examples_for "with an admin user" do
    let(:user) { admin }

    before do
      project.save!
      user.save!
    end

    context "without the user being a member" do
      it_behaves_like "includes the project"
    end

    context "without the project being active" do
      let(:project_status) { false }

      it_behaves_like "is empty"
    end

    context "without the project being active " \
            "with the permission being public" do
      let(:project_status) { false }

      it "is empty" do
        expect(described_class.allowed_to(user, public_action)).to be_empty
      end
    end

    context "with the project being active with the permission being public" do
      it "includes the project" do
        expect(described_class.allowed_to(user, public_action)).to contain_exactly(project)
      end
    end

    context "without the project module being active" do
      before do
        project.enabled_modules = []
      end

      it_behaves_like "is empty"
    end

    context "with the user being locked" do
      before do
        user.update!(status: Principal.statuses[:locked])
      end

      it_behaves_like "is empty"
    end
  end

  context "with the project being private" do
    let(:project) { private_project }

    it_behaves_like "member based allowed to check"
    it_behaves_like "with an admin user"

    context "with the user not being logged in" do
      before do
        project.save!
        anonymous.save!
        anonymous_role.save!
      end

      context "with the anonymous role having the permission" do
        it "is empty" do
          expect(described_class.allowed_to(anonymous, action)).to be_empty
        end
      end

      context "with the permission being public" do
        it "is empty" do
          expect(described_class.allowed_to(anonymous, public_action)).to be_empty
        end
      end
    end
  end

  context "with the project being public" do
    let(:project) { public_project }

    it_behaves_like "member based allowed to check"
    it_behaves_like "with an admin user"

    context "with the user not being logged in" do
      before do
        project.save!
        anonymous.save!
        anonymous_role.save!
      end

      context "with the anonymous role having the permission" do
        it "includes the project" do
          expect(described_class.allowed_to(anonymous, action)).to contain_exactly(project)
        end
      end

      context "with the permission being disabled" do
        let(:permission) { OpenProject::AccessControl.permission(action) }

        around do |example|
          permission.disable!
          OpenProject::AccessControl.clear_caches
          example.run
        ensure
          permission.enable!
          OpenProject::AccessControl.clear_caches
        end

        it "is empty" do
          expect(described_class.allowed_to(anonymous, action)).to be_empty
        end
      end

      context "with the anonymous role having the permission " \
              "without the project being active" do
        let(:project_status) { false }

        it "is empty" do
          expect(described_class.allowed_to(anonymous, action)).to be_empty
        end
      end

      context "without the anonymous role having the permission" do
        let(:anonymous_permissions) { [] }

        it "is empty" do
          expect(described_class.allowed_to(anonymous, action)).to be_empty
        end
      end

      context "with the permission being public" do
        it "includes the project" do
          expect(described_class.allowed_to(anonymous, public_action)).to contain_exactly(project)
        end
      end

      context "with the permission being public " \
              "with the associated module not being active" do
        before do
          project.enabled_modules = []
        end

        it "is empty" do
          expect(described_class.allowed_to(anonymous, public_action)).to be_empty
        end
      end

      context "with the permission being public and not module bound " \
              "with no module being active" do
        before do
          project.enabled_modules = []
        end

        it "includes the project" do
          expect(described_class.allowed_to(anonymous, public_non_module_action)).to contain_exactly(project)
        end
      end
    end

    context "with the user being member" do
      before do
        project.save!
        user.save!
        non_member_role.save!
        member.save!
      end

      context "with the role not having the permission " \
              "with non member having the permission" do
        let(:permissions) { [] }
        let(:non_member_permissions) { [action] }

        it_behaves_like "is empty"
      end
    end

    context "without the user being member" do
      before do
        project.save!
        user.save!
        non_member_role.save!
      end

      context "with the non member role having the permission" do
        it_behaves_like "includes the project"
      end

      context "with the non member role having the permission " \
              "without the project being active" do
        let(:project_status) { false }

        it_behaves_like "is empty"
      end

      context "with the permission being public and not module bound " \
              "without the project being active" do
        let(:project_status) { false }

        it "is empty" do
          expect(described_class.allowed_to(user, public_non_module_action)).to be_empty
        end
      end

      context "without the non member role having the permission" do
        let(:non_member_permissions) { [] }

        it_behaves_like "is empty"
      end

      context "with the permission being public" do
        it "includes the project" do
          expect(described_class.allowed_to(user, public_action)).to contain_exactly(project)
        end
      end

      context "with the permission being public " \
              "with the module not being active" do
        before do
          project.enabled_modules = []
        end

        it "is empty" do
          expect(described_class.allowed_to(user, public_action)).to be_empty
        end
      end

      context "with the permission being public and not module bound " \
              "with no module active" do
        before do
          project.enabled_modules = []
        end

        it "includes the project" do
          expect(described_class.allowed_to(user, public_non_module_action)).to contain_exactly(project)
        end
      end
    end
  end
end
