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

RSpec.describe Attachments::ClaimableIdsFromText do
  shared_let(:user) { create(:user) }
  shared_let(:other_user) { create(:user) }
  shared_let(:own_uncontainered) { create(:attachment, author: user, container: nil) }

  subject(:claimable_ids) { described_class.call(text, user:) }

  context "when the text is blank" do
    let(:text) { "" }

    it "returns an empty array without querying" do
      allow(Attachment).to receive(:where)

      expect(claimable_ids).to eq([])
      expect(Attachment).not_to have_received(:where)
    end
  end

  context "when the text is nil" do
    let(:text) { nil }

    it "returns an empty array without querying" do
      allow(Attachment).to receive(:where)

      expect(claimable_ids).to eq([])
      expect(Attachment).not_to have_received(:where)
    end
  end

  context "when the text references an inline image attachment" do
    let(:text) { %(<img class="op-uc-image" src="/api/v3/attachments/#{own_uncontainered.id}/content">) }

    it { is_expected.to contain_exactly(own_uncontainered.id) }
  end

  context "when the text references an attachment via markdown" do
    let(:text) { "![](/api/v3/attachments/#{own_uncontainered.id}/content)" }

    it { is_expected.to contain_exactly(own_uncontainered.id) }
  end

  context "when the same attachment is referenced multiple times" do
    let(:text) do
      "#{own_uncontainered.id} " \
        "![](/api/v3/attachments/#{own_uncontainered.id}/content) " \
        "<img src=\"/api/v3/attachments/#{own_uncontainered.id}/content\">"
    end

    it { is_expected.to contain_exactly(own_uncontainered.id) }
  end

  context "when the attachment belongs to another user" do
    shared_let(:other_users_attachment) { create(:attachment, author: other_user, container: nil) }

    let(:text) { "![](/api/v3/attachments/#{other_users_attachment.id}/content)" }

    it { is_expected.to eq([]) }
  end

  context "when the attachment is already containered elsewhere" do
    shared_let(:containered_attachment) { create(:attachment, author: user, container: create(:work_package)) }

    let(:text) { "![](/api/v3/attachments/#{containered_attachment.id}/content)" }

    it { is_expected.to eq([]) }
  end
end
