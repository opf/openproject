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

RSpec.describe Versions::Scopes::SharedWith do
  shared_let(:root_project) { create(:project) }
  shared_let(:parent_project) { create(:project, parent: root_project) }
  shared_let(:project) { create(:project, parent: parent_project) }
  shared_let(:other_root_project) { create(:project) }
  shared_let(:aunt_project) { create(:project, parent: root_project) }
  shared_let(:sibling_project) { create(:project, parent: parent_project) }
  shared_let(:child_project) { create(:project, parent: project) }
  shared_let(:grand_child_project) { create(:project, parent: child_project) }

  describe ".shared_with" do
    context "with the version not being shared" do
      let!(:version) { create(:version, project:, sharing: "none") }

      it "is visible within the original project" do
        expect(Version.shared_with(project))
          .to contain_exactly(version)
      end

      it "is not visible in any other project" do
        [parent_project,
         root_project,
         other_root_project,
         aunt_project,
         sibling_project,
         child_project,
         grand_child_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end
    end

    context "with the version being shared with descendants" do
      let!(:version) { create(:version, project:, sharing: "descendants") }

      it "is visible within the original project and it`s descendants" do
        [project,
         child_project,
         grand_child_project].each do |p|
          expect(Version.shared_with(p))
            .to contain_exactly(version)
        end
      end

      it "is not visible in any other project" do
        [parent_project,
         root_project,
         other_root_project,
         aunt_project,
         sibling_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end

      it "is not visible in any other project if the project is inactive" do
        project.update(active: false)

        [parent_project,
         root_project,
         child_project,
         grand_child_project,
         aunt_project,
         sibling_project,
         other_root_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end
    end

    context "with the version being shared with hierarchy" do
      let!(:version) { create(:version, project:, sharing: "hierarchy") }

      it "is visible within the original project and it`s descendants and ancestors" do
        [project,
         parent_project,
         root_project,
         child_project,
         grand_child_project].each do |p|
          expect(Version.shared_with(p))
            .to contain_exactly(version)
        end
      end

      it "is not visible in any other project" do
        [other_root_project,
         aunt_project,
         sibling_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end

      it "is not visible in any other project if the project is inactive" do
        project.update(active: false)

        [parent_project,
         root_project,
         child_project,
         grand_child_project,
         aunt_project,
         sibling_project,
         other_root_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end
    end

    context "with the version being shared with tree" do
      let(:version) { create(:version, project:, sharing: "tree") }

      it "is visible within the original project and every project within the same tree" do
        [project,
         parent_project,
         root_project,
         child_project,
         grand_child_project,
         aunt_project,
         sibling_project].each do |p|
          expect(Version.shared_with(p))
            .to contain_exactly(version)
        end
      end

      it "is not visible projects outside of the tree" do
        [other_root_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end

      it "is not visible in any other project if the project is inactive" do
        project.update(active: false)

        [parent_project,
         root_project,
         child_project,
         grand_child_project,
         aunt_project,
         sibling_project,
         other_root_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end
    end

    context "with the version being shared with system" do
      let(:version) { create(:version, project:, sharing: "system") }

      it "is visible in all projects" do
        [project,
         parent_project,
         root_project,
         child_project,
         grand_child_project,
         aunt_project,
         sibling_project,
         other_root_project].each do |p|
          expect(Version.shared_with(p))
            .to contain_exactly(version)
        end
      end

      it "is not visible in any other project if the project is inactive" do
        project.update(active: false)

        [parent_project,
         root_project,
         child_project,
         grand_child_project,
         aunt_project,
         sibling_project,
         other_root_project].each do |p|
          expect(Version.shared_with(p))
            .to be_empty
        end
      end
    end
  end
end
