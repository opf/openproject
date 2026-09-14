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

RSpec.describe AddWorkPackageNoteService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:instance) do
    described_class.new(user:,
                        work_package:)
  end

  describe ".contract" do
    it "uses the CreateNoteContract contract" do
      expect(instance.contract_class).to eql WorkPackages::CreateNoteContract
    end
  end

  describe "call" do
    let(:mock_contract) do
      class_double(WorkPackages::CreateNoteContract,
                   new: mock_contract_instance)
    end

    let(:mock_contract_instance) do
      instance_double(WorkPackages::CreateNoteContract,
                      errors: contract_errors,
                      validate: valid_contract)
    end
    let(:valid_contract) { true }
    let(:contract_errors) { instance_double(ActiveModel::Errors, full_messages: ["error message"]) }
    let(:claims_service) { WorkPackages::ActivitiesTab::CommentAttachmentsClaims::ClaimsService }
    let(:mock_claim_service_instance) do
      instance_double(claims_service, call: ServiceResult.success(result: []))
    end

    let(:send_notifications) { false }

    before do
      allow(instance).to receive(:contract_class).and_return(mock_contract)
      allow(work_package).to receive(:add_journal).and_call_original
      allow(work_package).to receive(:save_journals).and_return(true)
      allow(claims_service).to receive(:new).and_return(mock_claim_service_instance)
    end

    subject { instance.call("blubs", send_notifications:) }

    it "persists the value" do
      expect(subject).to be_success
      expect(work_package).to have_received(:add_journal)
        .with(user: user, notes: "blubs", internal: false)
      expect(work_package).to have_received(:save_journals)
    end

    context "with internal note" do
      subject { instance.call("blubs", send_notifications:, internal: true) }

      it "persists the value" do
        expect(subject).to be_success
        expect(work_package).to have_received(:add_journal)
          .with(user: user, notes: "blubs", internal: true)
        expect(work_package).to have_received(:save_journals)
      end
    end

    context "when the journal notes have attachments" do
      let(:attachment1) { build_stubbed(:attachment) }
      let(:attachment2) { build_stubbed(:attachment) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">
          Lorem ipsum dolor sit amet
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">
          consectetur adipiscing elit
        HTML
      end

      let(:mock_claim_service_instance) do
        instance_double(claims_service, call: ServiceResult.success(result: [attachment1, attachment2]))
      end

      subject { instance.call(notes, send_notifications:) }

      context "and note creation is successful" do
        it "creates an attachment claim" do
          expect(subject).to be_success
          expect(WorkPackages::ActivitiesTab::CommentAttachmentsClaims::ClaimsService)
            .to have_received(:new).with(user: user, model: work_package.journals.last)

          dependent_results = subject.dependent_results
          expect(dependent_results.size).to eq(1)
          expect(dependent_results.first).to be_a_success
          expect(dependent_results.first.result).to contain_exactly(attachment1, attachment2)
        end
      end

      context "and note creation is unsuccessful" do
        let(:valid_contract) { false }

        it "does not create an attachment claim" do
          expect(subject).to be_a_failure
          expect(WorkPackages::ActivitiesTab::CommentAttachmentsClaims::ClaimsService)
            .not_to have_received(:new)

          expect(subject.dependent_results).to be_empty
        end
      end
    end

    it "creates an advisory lock" do
      allow(OpenProject::Mutex)
        .to receive(:with_advisory_lock_transaction)
        .with(work_package)
        .and_call_original

      subject

      expect(OpenProject::Mutex)
        .to have_received(:with_advisory_lock_transaction)
    end

    it "sends notifications" do
      allow(Journal::NotificationConfiguration)
        .to receive(:with)
        .with(send_notifications)
        .and_yield

      subject

      expect(Journal::NotificationConfiguration)
        .to have_received(:with)
    end

    it "has no errors" do
      expect(subject.errors).to be_empty
    end

    context "when the contract does not validate" do
      let(:valid_contract) { false }

      it "is unsuccessful" do
        expect(subject.success?).to be_falsey
      end

      it "does not persist the changes" do
        expect(work_package).not_to receive(:save_journals)

        subject
      end

      it "exposes the contract's errors" do
        errors = double("errors")
        allow(mock_contract_instance).to receive(:errors).and_return(errors)

        subject

        expect(subject.errors).to eql errors
      end
    end

    context "when the saving is unsuccessful" do
      before do
        expect(work_package).to receive(:save_journals).and_return false
      end

      it "is unsuccessful" do
        expect(subject).not_to be_success
      end

      it "leaves the value unchanged" do
        subject

        expect(work_package.journal_notes).to eql "blubs"
        expect(work_package.journal_user).to eql user
      end

      it "exposes the work_packages's errors" do
        errors = double("errors")
        allow(work_package).to receive(:errors).and_return(errors)

        subject

        expect(subject.errors).to eql errors
      end
    end
  end

  describe "integration" do
    let(:user) { create(:admin) }
    let(:project) { create(:project) }
    let(:work_package) { create(:work_package, project:) }

    before do
      create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |custom_field|
        project.enabled_variants.first.custom_fields << custom_field
        project.work_package_custom_fields << custom_field
      end
    end

    it "adds a comment when another required work package field is invalid" do
      result = described_class.new(user:, work_package:).call("A comment", send_notifications: false)

      expect(result).to be_success
      expect(work_package.journals.reload.last.notes).to eq("A comment")
    end
  end
end
