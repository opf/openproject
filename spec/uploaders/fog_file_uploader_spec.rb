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

RSpec.describe FogFileUploader,
               with_config: {
                 attachments_storage: :fog,
                 fog: {
                   directory: MockCarrierwave.bucket,
                   credentials: MockCarrierwave.credentials
                 }
               } do
  let(:model) { Attachment.new }
  let(:uploader) { described_class.new(model, :file) }
  let(:content) { "a" * 500_000 } # larger than fog-aws/excon's chunk size to exercise multiple reads

  before do
    file = CarrierWave::SanitizedFile.new(
      tempfile: StringIO.new(content),
      filename: "test.bin",
      content_type: "application/octet-stream"
    )

    uploader.store!(file)
  end

  describe "#stream_to" do
    it "writes the remote object's content to the given IO without buffering it as a whole" do
      # CarrierWave::SanitizedFile#read is what buffers a whole remote file into memory
      # (see CarrierWave::Storage::Fog::File#read); #stream_to must not go through it.
      # rubocop:disable RSpec/AnyInstance
      expect_any_instance_of(CarrierWave::SanitizedFile).not_to receive(:read)
      # rubocop:enable RSpec/AnyInstance

      io = StringIO.new
      uploader.stream_to(io)

      expect(io.string).to eq(content)
    end
  end
end
