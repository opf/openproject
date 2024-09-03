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

require "spec_helper"

RSpec.describe Attachments::DeleteService, "integration", with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:call) { described_class.new(model: attachment, user:).call }

  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:project) { create(:project) }
  let(:attachment) { create(:attachment, container:, author:) }
  let(:author) { user }

  describe "#call" do
    context "when container is journalized" do
      let(:container) { create(:work_package, project:) }
      let(:permissions) { %i[edit_work_packages] }

      shared_examples "successful deletion" do
        it "is successful" do
          expect(call)
            .to be_success
        end

        it "removes the attachment" do
          expect(Attachment.where(id: attachment.id))
            .not_to exist
        end

        it "adds a journal entry to the container" do
          expect(container.journals.reload.count).to eq 3 # 1 for WP creation + 1 for adding the attachment + 1 for deletion
        end

        it "updates the timestamp on the container" do
          expect(container.reload.updated_at)
            .not_to eql timestamp_before
        end
      end

      context "with a valid container" do
        let!(:timestamp_before) { container.updated_at }

        before do
          # Force to have a journal for the attachment
          attachment
          container.add_journal(user:)
          container.save!

          call
        end

        it_behaves_like "successful deletion"
      end

      context "with an invalid container" do
        let!(:timestamp_before) { container.updated_at }

        before do
          # Force to have a journal for the attachment
          attachment
          container.add_journal(user:, notes: "Some notes")
          container.save!

          # have an invalid work package
          container.update_column(:subject, "")

          call
        end

        it_behaves_like "successful deletion"
      end
    end

    context "when not journalized" do
      let(:container) { create(:message, forum:) }
      let(:forum) { create(:forum, project:) }
      let(:permissions) { %i[delete_messages edit_messages] }

      shared_examples "successful deletion" do
        it "is successful" do
          expect(call)
            .to be_success
        end

        it "removes the attachment" do
          expect(Attachment.where(id: attachment.id))
            .not_to exist
        end

        it "updates the timestamp on the container" do
          expect(container.reload.updated_at)
            .not_to eql timestamp_before
        end
      end

      context "with a valid container" do
        let!(:timestamp_before) { container.updated_at }

        before do
          call
        end

        it_behaves_like "successful deletion"
      end

      context "with an invalid container" do
        let!(:timestamp_before) { container.updated_at }

        before do
          # have an invalid container
          container.update_column(:subject, "")

          call
        end

        it_behaves_like "successful deletion"
      end
    end

    context "when uncontainered" do
      let(:container) { nil }
      let(:permissions) { [] }

      before do
        call
      end

      context "when the user is the attachment author" do
        it "is successful" do
          expect(call)
            .to be_success
        end

        it "removes the attachment" do
          expect(Attachment.where(id: attachment.id))
            .not_to exist
        end
      end

      context "with the user not being the attachment author" do
        let(:author) { create(:user) }

        it "fails" do
          expect(call)
            .to be_failure
        end

        it "keeps the attachment" do
          expect(Attachment.find(attachment.id))
            .to eql attachment
        end
      end
    end
  end
end
