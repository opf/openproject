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

RSpec.describe WorkPackages::CreateService, "integration", type: :model do
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages manage_subtasks])
  end

  let(:type) do
    create(:type,
           custom_fields: [custom_field])
  end
  let(:default_type) do
    create(:type_standard)
  end
  let(:project) { create(:project, types: [type, default_type]) }
  let(:parent) do
    create(:work_package,
           subject: "parent",
           project:,
           type:)
  end
  let(:instance) { described_class.new(user:) }
  let(:custom_field) { create(:work_package_custom_field) }
  let(:other_status) { create(:status) }
  let(:default_status) { create(:default_status) }
  let(:priority) { create(:priority) }
  let(:default_priority) { create(:default_priority) }
  let(:attributes) { {} }
  let(:new_work_package) do
    service_result
      .result
  end
  let(:service_result) do
    instance
      .call(**attributes)
  end

  before do
    other_status
    default_status
    priority
    default_priority
    type
    default_type
    login_as(user)
  end

  context "when the only type of the project is a milestone" do
    let(:default_type) do
      create(:type_milestone)
    end
    let(:project) { create(:project, types: [default_type]) }

    describe "call without date attributes" do
      let(:attributes) do
        { subject: "blubs", project: }
      end

      it "creates the default type without errors" do
        expect(service_result).to be_success
        expect(service_result.errors).to be_empty
      end
    end

    describe "call with a parent non-milestone with dates" do
      let(:parent) do
        create(:work_package,
               project:,
               start_date: "2024-01-01",
               due_date: "2024-01-10",
               type: create(:type))
      end
      let(:attributes) do
        { subject: "blubs", project:, parent: }
      end

      it "creates the default type without errors" do
        expect(service_result).to be_success
        expect(service_result.errors).to be_empty
      end
    end
  end

  describe "#call" do
    let(:attributes) do
      { subject: "blubs",
        project:,
        estimated_hours: 10.0,
        remaining_hours: 5.0,
        parent:,
        start_date: Date.current,
        due_date: Date.current + 3.days }
    end

    it "creates the work_package with the provided attributes and sets the user as a watcher" do
      # successful
      expect(service_result)
        .to be_success

      # attributes set as desired
      attributes.each do |key, value|
        expect(new_work_package.send(key))
          .to eql value
      end

      # service user as author
      expect(new_work_package.author)
        .to eql(user)

      # assign the default status
      expect(new_work_package.status)
        .to eql(default_status)

      # assign the first type in the project (not related to is_default)
      expect(new_work_package.type)
        .to eql(type)

      # assign the default priority
      expect(new_work_package.priority)
        .to eql(default_priority)

      # parent updated
      parent.reload
      expect(parent.derived_done_ratio)
        .to eq 50
      expect(parent.start_date)
        .to eql attributes[:start_date]
      expect(parent.due_date)
        .to eql attributes[:due_date]

      # adds the user (author) as watcher
      expect(new_work_package.watcher_users)
        .to contain_exactly(user)
    end

    describe "setting the attachments" do
      let!(:other_users_attachment) do
        create(:attachment, container: nil, author: create(:user))
      end
      let!(:users_attachment) do
        create(:attachment, container: nil, author: user)
      end

      it "reports on invalid attachments and sets the new if everything is valid" do
        result = instance.call(**attributes.merge(attachment_ids: [other_users_attachment.id]))

        expect(result)
          .to be_failure

        expect(result.errors.symbols_for(:attachments))
          .to contain_exactly(:does_not_exist)

        # The parent work package
        expect(WorkPackage.count)
          .to be 1

        expect(other_users_attachment.reload.container)
          .to be_nil

        result = instance.call(**attributes.merge(attachment_ids: [users_attachment.id]))

        expect(result)
          .to be_success

        expect(result.result.attachments)
          .to contain_exactly(users_attachment)

        expect(users_attachment.reload.container)
          .to eql result.result
      end
    end

    describe "with a child creation with both dates and work" do
      let(:start_date) { Date.current }
      let(:due_date) { start_date + 3.days }
      let(:attributes) do
        {
          subject: "child",
          project:,
          parent:,
          estimated_hours: 5,
          start_date:,
          due_date:
        }
      end

      it "correctly updates the parent values" do
        expect(service_result)
          .to be_success

        parent.reload
        expect(parent.derived_estimated_hours).to eq(5)
        expect(parent.start_date).to eq(start_date)
        expect(parent.due_date).to eq(due_date)
      end
    end

    describe "writing timestamps" do
      shared_let(:user) { create(:admin) }
      shared_let(:other_user) { create(:user) }

      let(:created_at) { 11.days.ago }

      let(:attributes) do
        {
          subject: "child",
          project:,
          author: other_user,
          created_at:
        }
      end

      context "when enabled", with_settings: { apiv3_write_readonly_attributes: true } do
        it "sets created_at accordingly" do
          expect(service_result)
            .to be_success

          expect(new_work_package.created_at).to equal_time_without_usec(created_at)
        end
      end

      context "when enabled, but disallowed field", with_settings: { apiv3_write_readonly_attributes: true } do
        let(:attributes) do
          {
            subject: "child",
            project:,
            author: other_user,
            updated_at: created_at
          }
        end

        it "rejects updated_at" do
          expect(service_result)
            .not_to be_success

          expect(new_work_package.errors.symbols_for(:updated_at))
            .to contain_exactly(:error_readonly)
        end
      end

      context "when disabled", with_settings: { apiv3_write_readonly_attributes: false } do
        it "rejects the creation" do
          expect(service_result)
            .not_to be_success

          expect(new_work_package.errors.symbols_for(:created_at))
            .to contain_exactly(:error_readonly)
        end
      end
    end
  end
end
