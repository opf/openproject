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

RSpec.describe Attachment, "Shrine storage" do
  def upload(content = "first", filename: "plan.txt")
    FileHelpers.mock_uploaded_file(name: filename, content:)
  end

  it "dual-writes the filename and canonical key, readable by the former CarrierWave mount" do
    attachment = create(:attachment, file: upload, content_type: nil)
    attachment.reload
    expected_key = "attachment/file/#{attachment.id}/plan.txt"
    expect(attachment[:file]).to eq("plan.txt")
    expect(attachment.file_data).to include("storage" => "store", "id" => expected_key,
                                            "metadata" => include("filename" => "plan.txt", "size" => 5))
    previous = LocalFileUploader.new(attachment, :file)
    previous.retrieve_from_store!(attachment[:file])
    expect(previous.read).to eq("first")
  end

  it "reads, copies, streams and deletes a pre-Shrine row" do
    original = create(:attachment, file: upload)
    original.update_column(:file_data, nil)
    original.reload
    copy = original.copy
    copy.save!
    streamed = StringIO.new
    copy.reload.file.stream_to(streamed)
    expect(streamed.string).to eq("first")
    expect(copy.filename).to eq("plan.txt")
    original.destroy!
    expect(original.file).not_to be_readable
    expect(copy.file.read).to eq("first")
  end

  it "leaves the committed bytes untouched while a same-name replacement is uncommitted" do
    row = create(:attachment, file: upload)
    original_path = row.file.path

    described_class.transaction(requires_new: true) do
      row.update!(file: upload("revision"))
      expect(row.file.path).not_to eq(original_path)
      expect(File.binread(original_path)).to eq("first")
      expect(row.filename).to eq("plan.txt")
      expect(row.file.read).to eq("revision")
      raise ActiveRecord::Rollback
    end
  end

  it "materializes the latest replacement for the previous release and can be run twice" do
    row = create(:attachment, file: upload)
    row.update!(file: upload("revision"))
    2.times { row.file.prepare_carrierwave_rollback! }
    expect(row.reload.file_data).to be_nil
    previous = LocalFileUploader.new(row, :file)
    previous.retrieve_from_store!(row[:file])
    expect(previous.read).to eq("revision")
    expect(row.filename).to eq("plan.txt")
  end

  it "retains Shrine metadata if a canonical file fails verification during rollback preparation" do
    row = create(:attachment, file: upload)
    File.binwrite(row.file.path, "other")
    expect { row.file.prepare_carrierwave_rollback! }.to raise_error(IOError, /digest/)
    expect(row.reload.file_data).to be_present
  end

  it "restores the original bytes and metadata on same-key replacement rollback" do
    original = create(:attachment, file: upload)
    original.reload
    data = original.file_data

    described_class.transaction(requires_new: true) do
      original.update!(file: upload("second"))
      original.update!(file: upload("third"))
      expect(original.file.read).to eq("third")
      raise ActiveRecord::Rollback
    end

    expect(original.reload.file.read).to eq("first")
    expect(original.file_data).to eq(data)
    expect(original.digest).to eq(Digest::MD5.hexdigest("first"))
  end

  it "restores the committed same-name version when a stale writer rolls back" do
    original = create(:attachment, file: upload)
    stale = described_class.find(original.id)
    original.update!(file: upload("committed revision"))

    described_class.transaction(requires_new: true) do
      stale.update!(file: upload("discard"))
      raise ActiveRecord::Rollback
    end

    expect(original.reload.file.read).to eq("committed revision")
    expect(original.digest).to eq(Digest::MD5.hexdigest("committed revision"))
  end

  it "removes the committed renamed file when a stale writer restores the original filename and bytes" do
    original = create(:attachment, file: upload)
    stale = described_class.find(original.id)
    original.update!(file: upload("committed revision", filename: "renamed.txt"))
    replaced_path = original.file.path

    stale.update!(file: upload)

    expect(stale.reload.filename).to eq("plan.txt")
    expect(stale.file.read).to eq("first")
    expect(stale.filesize).to eq(5)
    expect(stale.digest).to eq(Digest::MD5.hexdigest("first"))
    expect(File.exist?(replaced_path)).to be(false)
  end

  it "restores a legacy file whose stored digest was blank" do
    original = create(:attachment, file: upload)
    original.update_columns(file_data: nil, digest: "")

    described_class.transaction(requires_new: true) do
      original.update!(file: upload("revision"))
      raise ActiveRecord::Rollback
    end

    expect(original.reload.file.read).to eq("first")
    expect(original.digest).to eq("")
    expect(original.file_data).to be_nil
  end

  it "deletes the permanent object when a different file has been assigned without saving" do
    original = create(:attachment, file: upload)
    path = original.file.path
    original.file = upload("discard", filename: "pending.txt")
    cache_path = original.file.path
    original.destroy!
    expect(File.exist?(path)).to be(false)
    expect(File.exist?(cache_path)).to be(false)
  end

  it "discards new bytes on rollback and can retry the same record" do
    original = build(:attachment, author: create(:user), container: nil, file: upload)
    key = nil
    described_class.transaction(requires_new: true) do
      original.save!
      key = original.file.path
      raise ActiveRecord::Rollback
    end
    expect(File.exist?(key)).to be(false)
    original.save!
    expect(original.reload.file.read).to eq("first")
  end
end
