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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("db/migrate/20260218095806_apply_work_package_attachment_settings_to_existing_projects.rb")

RSpec.describe ApplyWorkPackageAttachmentSettingsToExistingProjects, type: :model do
  let(:project_with_visible_attachments) { create(:project) }
  let(:project_with_hidden_attachments) { create(:project) }
  let(:undecided_project) { create(:project) }

  before do
    project_with_visible_attachments.update!(settings: { some_unrelated_setting: 42, deactivate_work_package_attachments: false })
    project_with_hidden_attachments.update!(settings: { some_unrelated_setting: 42, deactivate_work_package_attachments: true })
    undecided_project.update!(settings: { some_unrelated_setting: 42 })
  end

  # rubocop:disable RSpec/PredicateMatcher
  describe "up migration" do
    subject { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

    context "when the global setting does not exist" do
      it "does not change the configuration of already configured projects" do
        subject

        expect(project_with_visible_attachments.reload.deactivate_work_package_attachments?).to be_falsey
        expect(project_with_hidden_attachments.reload.deactivate_work_package_attachments?).to be_truthy
      end

      it "does not change unrelated settings" do
        subject

        expect(project_with_visible_attachments.reload.settings["some_unrelated_setting"]).to eq(42)
        expect(project_with_hidden_attachments.reload.settings["some_unrelated_setting"]).to eq(42)
        expect(undecided_project.reload.settings["some_unrelated_setting"]).to eq(42)
      end

      it "changes undecided projects to show attachments (default)" do
        subject

        expect(undecided_project.reload.deactivate_work_package_attachments?).to be_falsey
      end
    end

    context "when the global setting is to show attachments" do
      before do
        Setting.create!(name: "show_work_package_attachments", value: true)
      end

      it "does not change the configuration of already configured projects" do
        subject

        expect(project_with_visible_attachments.reload.deactivate_work_package_attachments?).to be_falsey
        expect(project_with_hidden_attachments.reload.deactivate_work_package_attachments?).to be_truthy
      end

      it "does not change unrelated settings" do
        subject

        expect(project_with_visible_attachments.reload.settings["some_unrelated_setting"]).to eq(42)
        expect(project_with_hidden_attachments.reload.settings["some_unrelated_setting"]).to eq(42)
        expect(undecided_project.reload.settings["some_unrelated_setting"]).to eq(42)
      end

      it "changes undecided projects to show attachments" do
        subject

        expect(undecided_project.reload.deactivate_work_package_attachments?).to be_falsey
      end
    end

    context "when the global setting is to hide attachments" do
      before do
        Setting.create!(name: "show_work_package_attachments", value: false)
      end

      it "does not change the configuration of already configured projects" do
        subject

        expect(project_with_visible_attachments.reload.deactivate_work_package_attachments?).to be_falsey
        expect(project_with_hidden_attachments.reload.deactivate_work_package_attachments?).to be_truthy
      end

      it "does not change unrelated settings" do
        subject

        expect(project_with_visible_attachments.reload.settings["some_unrelated_setting"]).to eq(42)
        expect(project_with_hidden_attachments.reload.settings["some_unrelated_setting"]).to eq(42)
        expect(undecided_project.reload.settings["some_unrelated_setting"]).to eq(42)
      end

      it "changes undecided projects to hide attachments" do
        subject

        expect(undecided_project.reload.deactivate_work_package_attachments?).to be_truthy
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher
end
