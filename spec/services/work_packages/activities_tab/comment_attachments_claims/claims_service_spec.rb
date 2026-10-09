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

RSpec.describe WorkPackages::ActivitiesTab::CommentAttachmentsClaims::ClaimsService do
  shared_let(:user) { create(:user) }
  shared_let(:work_package) { create(:work_package, author: user) }
  shared_let(:journal) { create(:work_package_journal, journable: work_package, version: 2, notes: "") }

  it_behaves_like "BaseServices update service" do
    let(:model_instance) { build_stubbed(:work_package_journal, journable: work_package, version: 2, notes: "") }
    let(:set_attributes_class) { WorkPackages::ActivitiesTab::CommentAttachmentsClaims::SetAttributesService }
    let(:contract_class) { WorkPackages::ActivitiesTab::CommentAttachmentsClaimsContract }
  end

  describe "#call" do
    context "when the journal has no notes" do
      subject(:attachment_claims_service) do
        described_class.new(
          user:,
          model: journal
        )
      end

      before do
        journal.update!(notes: "")
      end

      it "does not claim any attachments" do
        claim_result = attachment_claims_service.call
        expect(claim_result).to be_success

        expect(journal.reload.attachments).to be_empty
      end
    end

    context "when the journal has notes with attachments" do
      shared_let(:attachment1) { create(:attachment, author: user, container: nil) }
      shared_let(:attachment2) { create(:attachment, author: user, container: nil) }
      shared_let(:attachment3) { create(:attachment, author: user, container: nil) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">

          First attachment

          <br>

          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">

          Second attachment

          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment3.id}/content">

          Third attachment
        HTML
      end

      subject(:attachment_claims_service) do
        described_class.new(
          user:,
          model: journal
        )
      end

      before do
        journal.update!(notes:)
      end

      it "claims the attachments" do
        claim_result = attachment_claims_service.call
        expect(claim_result).to be_success

        expect(journal.reload.attachments).to contain_exactly(attachment1, attachment2, attachment3)
      end
    end

    context "with existing comment attachments" do
      let(:comment) do
        work_package.add_journal(user:, notes:)
        work_package.save(validate: false)
        work_package.journals.last
      end

      let(:existing_attachment) { create(:attachment, author: user, container: nil) }
      let(:existing_attachment_excluded) { create(:attachment, author: user, container: nil) }
      let(:newly_attached) { create(:attachment, author: user, container: nil) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{existing_attachment.id}/content">

          First attachment

          <br>

          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{newly_attached.id}/content">

          Second attachment
        HTML
      end

      before do
        comment.attachments << [existing_attachment, existing_attachment_excluded]
        comment.save(validate: false)
      end

      subject(:attachment_claims_service) do
        described_class.new(
          user: user,
          model: comment
        )
      end

      it "replaces the comment attachments with newly updated ones" do
        expect(comment.reload.attachments).to contain_exactly(existing_attachment, existing_attachment_excluded)

        claim_result = attachment_claims_service.call
        expect(claim_result).to be_success

        expect(comment.reload.attachments).to contain_exactly(existing_attachment, newly_attached)
        expect(Attachment.exists?(existing_attachment_excluded.id)).to be(false)
      end
    end
  end
end
