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
require "services/base_services/behaves_like_update_service"

RSpec.describe Journals::UpdateService do
  it_behaves_like "BaseServices update service" do
    let(:factory) { :journal }

    describe "Inline attachments" do
      let(:model_instance) { build_stubbed(:work_package_journal, notes: "Foobar") }
      let(:claims_service) { WorkPackages::ActivitiesTab::CommentAttachmentsClaims::ClaimsService }
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

      let(:call_attributes) { { notes: } }

      let(:mock_claim_service_instance) do
        instance_double(claims_service, call: ServiceResult.success(result: [attachment1, attachment2]))
      end

      before do
        allow(claims_service).to receive(:new).and_return(mock_claim_service_instance)
      end

      context "when the journal notes have attachments" do
        context "and note creation is successful" do
          it "creates an attachment claim" do
            expect(subject).to be_success
            expect(claims_service)
              .to have_received(:new).with(user: user, model: model_instance)

            dependent_results = subject.dependent_results
            expect(dependent_results.size).to eq(1)
            expect(dependent_results.first).to be_a_success
            expect(dependent_results.first.result).to contain_exactly(attachment1, attachment2)
          end
        end

        context "and note creation is unsuccessful" do
          let(:model_save_result) { false }

          it "does not create an attachment claim" do
            expect(subject).to be_a_failure
            expect(claims_service)
              .not_to have_received(:new)

            expect(subject.dependent_results).to be_empty
          end
        end
      end

      context "with empty notes" do
        let(:model_instance) { build_stubbed(:work_package_journal, notes: "") }

        it "does not create an attachment claim" do
          expect(subject).to be_a_success

          expect(claims_service)
              .not_to have_received(:new)

          expect(subject.dependent_results).to be_empty
        end

        context "and previous attachments" do
          let(:user) { create(:user) }
          let(:work_package) { create(:work_package, author: user) }
          let(:model_instance) { create(:work_package_journal, journable: work_package, version: 2, notes: "") }

          let(:attachment1) { create(:attachment, container: model_instance) }
          let(:attachment2) { create(:attachment, container: model_instance) }

          before do
            model_instance.attachments << [attachment1, attachment2]
            model_instance.save(validate: false)
            allow(claims_service).to receive(:new).and_call_original
          end

          it "removes the previous attachments" do
            expect(model_instance.attachments).to contain_exactly(attachment1, attachment2)

            expect(subject).to be_a_success

            expect(model_instance.reload.attachments).to be_empty
            expect(Attachment.exists?(attachment1.id)).to be(false)
            expect(Attachment.exists?(attachment2.id)).to be(false)

            expect(claims_service).to have_received(:new)
          end
        end
      end
    end
  end

  describe "retracting a comment" do
    shared_let(:user) { create(:admin) }
    shared_let(:work_package) { create(:work_package) }

    let(:journal) do
      AddWorkPackageNoteService.new(user:, work_package:).call("A comment")
      work_package.last_journal
    end

    let(:notes) { "" }

    subject(:call) { described_class.new(model: journal, user:).call(notes:) }

    context "when the notes are emptied" do
      it "marks the journal with a comment retraction cause instead of leaving a noop" do
        expect(call).to be_success

        journal.reload
        expect(journal.cause).to eq("type" => "comment_retracted")
        expect(journal).not_to be_noop
        expect(journal.details).to have_key(:cause)
      end
    end

    context "when the notes are emptied on a journal that already has a cause" do
      let(:existing_cause) { Journal::CausedByWorkPackageParentDeletion.new.to_hash }

      before do
        journal.update_column(:cause, existing_cause)
      end

      it "keeps the existing cause" do
        expect(call).to be_success
        expect(journal.reload.cause).to eq(existing_cause)
      end
    end

    context "when the notes are changed" do
      let(:notes) { "An edited comment" }

      it "does not set a cause" do
        expect(call).to be_success
        expect(journal.reload.cause).to be_blank
      end
    end
  end
end
