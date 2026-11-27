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
require "shrine/storage/s3"

RSpec.describe Rake::Task, "attachments:prune_revisions" do
  include_context "rake"

  let(:task_name) { "attachments:prune_revisions" }
  let(:task_path) { "lib/tasks/attachment_revisions" }
  let(:storage) { AttachmentShrine.storage_for(:store) }
  let(:attachment) { create(:attachment) }

  around do |example|
    Dir.mktmpdir do |directory|
      example.metadata[:attachments_directory] = directory
      example.run
    end
  end

  before do |example|
    with_config attachments_storage: :file, attachments_storage_path: example.metadata.fetch(:attachments_directory)
  end

  def revision(id, filename = "plan.txt")
    "attachment/revisions/#{id}/#{SecureRandom.uuid}/#{filename}"
  end

  def store(key)
    storage.upload(StringIO.new(key), key)
    key
  end

  it "previews and removes unreferenced revisions while preserving the committed revision and other objects" do
    legacy = attachment.file_data.fetch("id")
    current = store(revision(attachment.id))
    attachment.update_column(:file_data, attachment.file_data.merge("id" => current))
    abandoned = store(revision(attachment.id, ".hidden"))
    deleted = store(revision(attachment.id + 1_000_000))
    foreign = store("attachment/revisions/#{attachment.id}/manual/plan.txt")

    expect { subject.invoke }.to output(/Would delete/).to_stdout
    expect([abandoned, deleted]).to all(satisfy { |key| storage.exists?(key) })
    subject.reenable
    expect { subject.invoke("apply") }.to output(/Deleted/).to_stdout
    expect([abandoned, deleted]).to all(satisfy { |key| !storage.exists?(key) })
    expect([current, legacy, foreign]).to all(satisfy { |key| storage.exists?(key) })

    subject.reenable
    expect { subject.invoke("apply") }.not_to output.to_stdout
  end

  it "retains an orphan after a failed delete and removes it on retry" do
    abandoned = store(revision(attachment.id))
    allow(AttachmentShrine).to receive(:storage_for).with(:store).and_return(storage)
    allow(storage).to receive(:delete).and_raise(IOError, "storage temporarily unavailable")

    expect { subject.invoke("apply") }.to raise_error(IOError)
    expect(storage.exists?(abandoned)).to be(true)
    allow(storage).to receive(:delete).and_call_original
    subject.reenable
    expect { subject.invoke("apply") }.to output("Deleted #{abandoned}\n").to_stdout
    expect(storage.exists?(abandoned)).to be(false)
  end

  it "limits S3 listing and deletion to the permanent store prefix" do
    key = revision(1_000_000_000)
    client = Aws::S3::Client.new(stub_responses: true)
    remote = Shrine::Storage::S3.new(bucket: "files", prefix: "uploads", client:)
    client.stub_responses(:list_objects_v2, contents: [{ key: "uploads/#{key}" }])
    allow(AttachmentShrine).to receive(:storage_for).with(:store).and_return(remote)

    expect { subject.invoke("apply") }.to output("Deleted #{key}\n").to_stdout
    expect(client.api_requests.map { |request| [request[:operation_name], request[:params]] }).to contain_exactly(
      [:list_objects_v2, include(bucket: "files", prefix: "uploads/attachment/revisions/")],
      [:delete_object, include(bucket: "files", key: "uploads/#{key}")]
    )
  end

  context "with a replacement before the first transaction commits" do
    include_context "with real database commits"

    it "rereads the attachment after acquiring the publisher's transaction lock" do
      reached_lock = Queue.new
      key = nil
      worker = nil

      Attachment.transaction do
        row = create(:attachment)
        row.update!(file: FileHelpers.mock_uploaded_file(name: "plan.txt", content: "revision"))
        key = row.reload.file_data.fetch("id")
        allow(AttachmentRevisionLock).to receive(:acquire).and_wrap_original do |original, id|
          reached_lock << Attachment.advisory_lock_exists?("attachment_revision_#{id}")
          original.call(id)
        end
        task = subject
        worker = Thread.new { Attachment.connection_pool.with_connection { task.invoke("apply") } }
        expect(reached_lock.pop(timeout: 10)).to be(true)
      end

      raise "collector did not finish" unless worker.join(10)

      worker.value
      expect(storage.exists?(key)).to be(true)
    ensure
      worker&.kill&.join
    end
  end
end
