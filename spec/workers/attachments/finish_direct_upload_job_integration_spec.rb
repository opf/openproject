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

RSpec.describe Attachments::FinishDirectUploadJob, "integration", type: :job do
  shared_let(:user) { create(:admin) }

  let!(:pending_attachment) do
    create(:attachment,
           author: user,
           status: :prepared,
           digest: "",
           container:)
  end

  let(:job) { described_class.new }

  shared_examples_for "turning pending attachment into a standard attachment" do
    it do
      job.perform(pending_attachment.id)

      attachment = Attachment.find(pending_attachment.id)

      expect(attachment.status).to eq "uploaded"
      expect(attachment.downloads)
        .to be(0)
      # expect to replace the content type with the actual value
      expect(attachment.content_type)
        .to eql("text/plain")
      expect(attachment.digest)
        .to eql("9473fdd0d880a43c21b7778d34872157")
    end
  end

  shared_examples_for "adding a journal to the attachment in the name of the attachment's author" do
    it do
      job.perform(pending_attachment.id)

      journals = Attachment.find(pending_attachment.id).journals

      expect(journals.count)
        .to be(2)

      expect(journals.last.user)
        .to eql(pending_attachment.author)
    end
  end

  context "for a journalized container" do
    let!(:container) { create(:work_package) }
    let!(:container_timestamp) { container.updated_at }

    it_behaves_like "turning pending attachment into a standard attachment"
    it_behaves_like "adding a journal to the attachment in the name of the attachment's author"

    it "adds a journal to the container in the name of the attachment's author" do
      job.perform(pending_attachment.id)

      journals = container.journals.reload

      expect(journals.count)
        .to be(2)

      expect(journals.last.user)
        .to eql(pending_attachment.author)

      expect(journals.last.created_at > container_timestamp)
        .to be_truthy

      container.reload

      expect(container.lock_version)
        .to be 0
    end

    describe "attachment created event" do
      let(:attachment_ids) { [] }

      let!(:subscription) do
        OpenProject::Notifications.subscribe(OpenProject::Events::ATTACHMENT_CREATED) do |payload|
          attachment_ids << payload[:attachment].id
        end
      end

      after do
        OpenProject::Notifications.unsubscribe(OpenProject::Events::ATTACHMENT_CREATED, subscription)
      end

      it "is triggered" do
        job.perform(pending_attachment.id)
        pending_attachment.reload
        expect(attachment_ids).to include(pending_attachment.id)
      end
    end
  end

  context "for a non journalized container" do
    let!(:container) { create(:wiki_page) }

    it_behaves_like "turning pending attachment into a standard attachment"
    it_behaves_like "adding a journal to the attachment in the name of the attachment's author"
  end

  context "for a nil container" do
    let!(:container) { nil }

    it_behaves_like "turning pending attachment into a standard attachment"
    it_behaves_like "adding a journal to the attachment in the name of the attachment's author"
  end

  context "with an incompatible attachment whitelist",
          with_settings: { attachment_whitelist: %w[image/png] } do
    let!(:container) { create(:work_package) }
    let!(:container_timestamp) { container.updated_at }

    it "Does not save the attachment" do
      allow(pending_attachment).to receive(:save!)
      allow(OpenProject.logger).to receive(:error)

      job.perform(pending_attachment.id)

      expect(pending_attachment).not_to have_received(:save!)
      expect(OpenProject.logger).to have_received(:error)

      container.reload

      expect(container.attachments).to be_empty
      expect { pending_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when the job is getting a whitelist override" do
      it "Does save the attachment" do
        job.perform(pending_attachment.id, whitelist: false)

        container.reload

        expect(container.attachments.count).to eq 1
        expect { pending_attachment.reload }.not_to raise_error(ActiveRecord::RecordNotFound)

        expect(pending_attachment.downloads).to eq 0
      end
    end
  end

  context "with the user not being allowed",
          with_settings: { attachment_whitelist: %w[image/png] } do
    shared_let(:user) { create(:user) }
    let!(:container) { create(:work_package) }

    it "Does not save the attachment" do
      allow(pending_attachment).to receive(:save!)

      job.perform(pending_attachment.id)

      expect(pending_attachment).not_to have_received(:save!)

      expect { pending_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
