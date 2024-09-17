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

RSpec.describe Sprint do
  let(:sprint) { build(:sprint) }
  let(:project) { build(:project) }

  describe "Class Methods" do
    describe "#displayed_left" do
      describe "WITH display set to left" do
        before do
          sprint.version_settings = [build(:version_setting, project:,
                                                             display: VersionSetting::DISPLAY_LEFT)]
          sprint.project = project
          sprint.save!
        end

        it {
          expect(Sprint.displayed_left(project)).to contain_exactly(sprint)
        }
      end

      describe "WITH a version setting defined for another project" do
        before do
          another_project = build(:project, name: "another project",
                                            identifier: "another project")

          sprint.version_settings = [build(:version_setting, project: another_project,
                                                             display: VersionSetting::DISPLAY_RIGHT)]
          sprint.project = project
          sprint.save
        end

        it { expect(Sprint.displayed_left(project)).to contain_exactly(sprint) }
      end

      describe "WITH no version setting defined" do
        before do
          sprint.project = project
          sprint.save!
        end

        it { expect(Sprint.displayed_left(project)).to contain_exactly(sprint) }
      end

      context "WITH a shared version from another project" do
        let!(:parent_project) { create(:project, identifier: "parent", name: "Parent") }

        let!(:home_project) do
          create(:project, identifier: "home", name: "Home").tap do |p|
            p.parent = parent_project
            p.save!
          end
        end

        let!(:sister_project) do
          create(:project, identifier: "sister", name: "Sister").tap do |p|
            p.parent = parent_project
            p.save!
          end
        end

        let!(:version) { create(:version, name: "Shared Version", sharing: "tree", project: home_project) }

        let(:displayed) { Sprint.apply_to(sister_project).displayed_left(sister_project) }

        describe "WITH no version settings" do
          it "includes the shared version by default" do
            expect(displayed).to contain_exactly(version)
          end
        end

        describe "WITH display = left in home project" do
          before do
            VersionSetting.create version:, project: home_project, display: VersionSetting::DISPLAY_LEFT
          end

          it "includes the shared version" do
            expect(displayed).to contain_exactly(version)
          end
        end

        describe "WITH display = none in home project" do
          before do
            VersionSetting.create version:, project: home_project, display: VersionSetting::DISPLAY_NONE
          end

          it "includes the shared version" do
            expect(displayed).to be_empty
          end
        end

        describe "WITH display = left in sister project" do
          before do
            VersionSetting.create version:, project: sister_project, display: VersionSetting::DISPLAY_LEFT
          end

          it "includes the shared version" do
            expect(displayed).to contain_exactly(version)
          end
        end

        describe "WITH display = none in sister project" do
          before do
            VersionSetting.create version:, project: sister_project, display: VersionSetting::DISPLAY_NONE
          end

          it "does not include the shared version" do
            expect(displayed).to be_empty
          end
        end

        describe "WITH display = left in home project and display = left in sister project" do
          before do
            VersionSetting.create version:, project: home_project, display: VersionSetting::DISPLAY_LEFT
            VersionSetting.create version:, project: sister_project, display: VersionSetting::DISPLAY_LEFT
          end

          it "includes the shared version" do
            expect(displayed).to contain_exactly(version)
          end
        end

        describe "WITH display = left in home project and display = none in sister project" do
          before do
            VersionSetting.create version:, project: home_project, display: VersionSetting::DISPLAY_LEFT
            VersionSetting.create version:, project: sister_project, display: VersionSetting::DISPLAY_NONE
          end

          it "does not include the shared version" do
            expect(displayed).to be_empty
          end
        end

        describe "WITH display = none in home project and display = left in sister project" do
          before do
            VersionSetting.create version:, project: home_project, display: VersionSetting::DISPLAY_NONE
            VersionSetting.create version:, project: sister_project, display: VersionSetting::DISPLAY_LEFT
          end

          it "includes the shared version" do
            expect(displayed).to contain_exactly(version)
          end
        end

        describe "WITH display = none in home project and display = none in sister project" do
          before do
            VersionSetting.create version:, project: home_project, display: VersionSetting::DISPLAY_NONE
            VersionSetting.create version:, project: sister_project, display: VersionSetting::DISPLAY_NONE
          end

          it "does not include the shared version" do
            expect(displayed).to be_empty
          end
        end
      end
    end

    describe "#displayed_right" do
      before do
        sprint.version_settings = [build(:version_setting, project:, display: VersionSetting::DISPLAY_RIGHT)]
        sprint.project = project
        sprint.save!
      end

      it { expect(Sprint.displayed_right(project)).to contain_exactly(sprint) }
    end

    describe "#order_by_date" do
      before do
        @sprint1 = create(:sprint, name: "sprint1", project:, start_date: Date.today + 2.days)
        @sprint2 = create(:sprint, name: "sprint2", project:, start_date: Date.today + 1.day,
                                   effective_date: Date.today + 3.days)
        @sprint3 = create(:sprint, name: "sprint3", project:, start_date: Date.today + 1.day,
                                   effective_date: Date.today + 2.days)
      end

      it "sorts the dates correctly", :aggregate_failures do
        expect(Sprint.order_by_date[0]).to eql @sprint3
        expect(Sprint.order_by_date[1]).to eql @sprint2
        expect(Sprint.order_by_date[2]).to eql @sprint1
      end
    end

    describe "#apply_to" do
      before do
        project.save
        @other_project = create(:project)
      end

      describe "WITH the version being shared system wide" do
        before do
          @version = create(:sprint, name: "systemwide", project: @other_project, sharing: "system")
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end

      describe "WITH the version being shared from a parent project" do
        before do
          project.update(parent: @other_project)
          project.reload
          @version = create(:sprint, name: "descended", project: @other_project, sharing: "descendants")
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end

      describe "WITH the version being shared within the tree" do
        before do
          @parent_project = create(:project)
          @other_project.update(parent: @parent_project)
          project.update(parent: @parent_project)
          project.reload
          @version = create(:sprint, name: "treed", project: @other_project, sharing: "tree")
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end

      describe "WITH the version being shared within the tree" do
        before do
          @descendant_project = create(:project, parent: project)
          project.reload
          @version = create(:sprint, name: "hierar", project: @descendant_project, sharing: "hierarchy")
        end

        it { expect(Sprint.apply_to(project).size).to eq(1) }
        it { expect(Sprint.apply_to(project)[0]).to eql(@version) }
      end
    end
  end

  describe "#wiki_page" do
    let(:wiki) { create :wiki, project: }
    let(:wiki_page) { WikiPage.where(wiki:, title: sprint.wiki_page).first }
    let(:user) { create :user }

    before do
      sprint.project = project
      sprint.save!
    end

    subject do
      login_as user

      sprint.wiki_page
    end

    it "creates a new wiki page if none is present" do
      expect { subject }.not_to raise_error

      expect(wiki_page.text).to start_with("h1. #{sprint.name}")
    end
  end
end
