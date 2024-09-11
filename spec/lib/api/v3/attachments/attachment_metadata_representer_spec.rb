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

RSpec.describe API::V3::Attachments::AttachmentParsingRepresenter do
  let(:current_user) { build_stubbed(:user) }
  let(:metadata) do
    data = API::ParserStruct.new
    data.filename = original_file_name
    data.description = original_description
    data.content_type = original_content_type
    data.filesize = original_file_size
    data.digest = original_digest
    data
  end
  let(:original_file_name) { "a file name" }
  let(:original_description) { "a description" }
  let(:original_content_type) { "text/plain" }
  let(:original_file_size) { 42 }
  let(:original_digest) { "0xFF" }
  let(:representer) { described_class.new(metadata, current_user:) }

  include API::V3::Utilities::PathHelper

  describe "parsing" do
    let(:parsed_hash) do
      {
        "metadata" => {
          "fileName" => "the parsed name",
          "description" => { "raw" => "the parsed description" },
          "contentType" => "text/html",
          "fileSize" => 43,
          "digest" => "0x00"
        }
      }
    end

    subject { metadata }

    before do
      representer.from_hash parsed_hash
    end

    it { expect(subject.filename).to eql("the parsed name") }
    it { expect(subject.description).to eql("the parsed description") }
    it { expect(subject.content_type).to eql("text/html") }
    it { expect(subject.filesize).to be(43) }
    it { expect(subject.digest).to eql("0x00") }
  end
end
