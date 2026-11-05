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

RSpec.describe Exports::PDF::Common::Attachments do
  let(:helper) do
    obj = Object.new
    obj.extend(described_class)
    obj.define_singleton_method(:api_url_helpers) { API::V3::Utilities::PathHelper::ApiV3Path }
    obj
  end

  describe "#extract_first_webp_frame" do
    after { helper.delete_all_resized_images }

    it "returns nil when the first animation frame does not start with an image chunk" do
      frame = ("\0".b * 16) + "ALPH".b + ("\0".b * 4)
      body = "WEBP".b + "ANMF".b + [frame.bytesize].pack("V") + frame
      bytes = "RIFF".b + [body.bytesize].pack("V") + body

      Tempfile.create(["frame", ".webp"]) do |file|
        file.binmode
        file.write(bytes)
        file.close

        result = Timeout.timeout(2) { helper.extract_first_webp_frame(file.path) }

        expect(result).to be_nil
      end
    end
  end
end
