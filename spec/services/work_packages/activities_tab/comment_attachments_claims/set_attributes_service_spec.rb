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

RSpec.describe WorkPackages::ActivitiesTab::CommentAttachmentsClaims::SetAttributesService do
  shared_let(:user) { create(:user) }
  shared_let(:other_user) { create(:user) }
  shared_let(:work_package) { create(:work_package, author: user) }
  shared_let(:journal) { create(:work_package_journal, journable: work_package, version: 2, notes: "") }

  current_user { user }

  subject(:set_attributes_service) do
    described_class.new(
      user:,
      model: journal,
      contract_class: EmptyContract
    ).call
  end

  describe "#call" do
    before do
      journal.update!(notes:)
    end

    context "when the journal notes have attachments" do
      shared_let(:attachment1) { create(:attachment, author: user, container: nil) }
      shared_let(:attachment2) { create(:attachment, author: user, container: nil) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment1.id}/content">
          Lorem ipsum dolor sit amet
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{attachment2.id}/content">
          consectetur adipiscing elit
        HTML
      end

      it "sets the attachments replacements" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to contain_exactly(attachment1, attachment2)
      end
    end

    context "when the journal notes reference containered attachments or attachments belonging to other users" do
      shared_let(:existing_work_package_attachment) { create(:attachment, author: user, container: work_package) }
      shared_let(:existing_journal_attachment) { create(:attachment, author: user, container: journal) }
      shared_let(:containered_attachment_other_user) { create(:attachment, author: other_user, container: work_package) }
      shared_let(:uncontainered_attachment_other_user) { create(:attachment, author: other_user, container: nil) }
      shared_let(:newly_attached) { create(:attachment, author: user, container: nil) }

      let(:notes) do
        <<~HTML
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{existing_work_package_attachment.id}/content">
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{existing_journal_attachment.id}/content">
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{containered_attachment_other_user.id}/content">
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{uncontainered_attachment_other_user.id}/content">
          <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{newly_attached.id}/content">
        HTML
      end

      it "sets attachment replacements only for attachments belonging to the journal and the user" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements)
          .to contain_exactly(existing_journal_attachment, newly_attached)
      end
    end

    context "when the journal notes have no attachments" do
      let(:notes) { "Lorem ipsum dolor sit amet" }

      it "defines empty attachments" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to be_empty
      end
    end

    context "when the journal notes are nil" do
      let(:notes) { nil }

      it "defines attachments as empty" do
        expect(set_attributes_service).to be_success
        expect(set_attributes_service.result.attachments_replacements).to eq([])
      end
    end
  end
end
