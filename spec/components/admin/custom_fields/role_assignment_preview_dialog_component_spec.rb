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

require "rails_helper"

RSpec.describe Admin::CustomFields::RoleAssignmentPreviewDialogComponent, type: :component do
  let(:old_role) { create(:project_role) }
  let(:new_role) { create(:project_role) }
  let(:custom_field) { create(:project_custom_field, :user, role: old_role) }

  let(:instance) do
    described_class.new(
      custom_field: custom_field,
      role: new_role
    )
  end

  describe "#membership_changes" do
    subject { instance.send(:membership_changes) }

    context "when no custom values exist" do
      it "does not return any changes" do
        expect(custom_field.custom_values).to be_empty
        expect(subject).to be_empty
      end
    end

    context "when a custom value exists and the user is not a member of the project" do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let!(:custom_value) do
        build(:custom_value, custom_field: custom_field, customized: project, value: user.id).tap { it.save(validate: false) }
      end

      it "returns that the user will get a new membership" do
        expect(subject.count).to eq(1)
        change = subject.first
        expect(change.user).to eq(user)
        expect(change.project).to eq(project)
        expect(change.change).to eq(I18n.t("custom_fields.admin.role_assignment.dialog.changes.new_member"))
      end
    end

    context "when a custom value exists and the user is already a member of the project with the old role" do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let!(:membership) { create(:member, project: project, user: user, roles: [old_role]) }
      let!(:custom_value) do
        build(:custom_value, custom_field: custom_field, customized: project, value: user.id).tap { it.save(validate: false) }
      end

      it "returns that the user will lose the old role and gain the new role" do
        expect(subject.count).to eq(1)
        change = subject.first
        expect(change.user).to eq(user)
        expect(change.project).to eq(project)
        expect(change.change).to eq(
          I18n.t(
            "custom_fields.admin.role_assignment.dialog.changes.gain_and_lose_role",
            old_role: old_role.name,
            new_role: new_role.name
          )
        )
      end
    end

    context "when a custom value exists and the user is already a member of the project but with a different role" do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:old_role) { nil }
      let!(:membership) { create(:member, project: project, user: user, roles: [create(:project_role)]) }
      let!(:custom_value) do
        build(:custom_value, custom_field: custom_field, customized: project, value: user.id).tap { it.save(validate: false) }
      end

      it "returns that the user will lose the old role and gain the new role" do
        expect(subject.count).to eq(1)
        change = subject.first
        expect(change.user).to eq(user)
        expect(change.project).to eq(project)
        expect(change.change).to eq(
          I18n.t(
            "custom_fields.admin.role_assignment.dialog.changes.gain_role",
            new_role: new_role.name
          )
        )
      end
    end

    context "when removing a role assignment" do
      context "when a custom value exists and the user is already a member of the project with only the old role" do
        let(:project) { create(:project) }
        let(:user) { create(:user) }
        let(:new_role) { nil }
        let!(:membership) { create(:member, project: project, user: user, roles: [old_role]) }
        let!(:custom_value) do
          build(:custom_value, custom_field: custom_field, customized: project, value: user.id).tap { it.save(validate: false) }
        end

        it "returns that the user will lose the old role and gain the new role" do
          expect(subject.count).to eq(1)
          change = subject.first
          expect(change.user).to eq(user)
          expect(change.project).to eq(project)
          expect(change.change).to eq(I18n.t("custom_fields.admin.role_assignment.dialog.changes.remove_member"))
        end
      end

      context "when a custom value exists and the user is already a member of the project with also the old role" do
        let(:project) { create(:project) }
        let(:user) { create(:user) }
        let(:new_role) { nil }
        let!(:membership) { create(:member, project: project, user: user, roles: [old_role, create(:project_role)]) }
        let!(:custom_value) do
          build(:custom_value, custom_field: custom_field, customized: project, value: user.id).tap do |cv|
            cv.save(validate: false)
          end
        end

        it "returns that the user will lose the old role and gain the new role" do
          expect(subject.count).to eq(1)
          change = subject.first
          expect(change.user).to eq(user)
          expect(change.project).to eq(project)
          expect(change.change).to eq(
            I18n.t(
              "custom_fields.admin.role_assignment.dialog.changes.lose_role",
              old_role: old_role.name
            )
          )
        end
      end
    end
  end
end
