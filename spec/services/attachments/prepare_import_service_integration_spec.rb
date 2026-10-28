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

RSpec.describe Attachments::PrepareImportService, "integration" do
  subject(:call) do
    described_class
      .new(user:, contract_class: EmptyContract)
      .call(filename: "Screen Shot.png", filesize: 1024, content_type: "image/png")
  end

  let(:user) { create(:user) }
  let(:attachment) { call.result }

  it "creates an attachment without a container" do
    expect(call).to be_success
    expect(attachment).to have_attributes(container: nil,
                                          status: "import_prepared",
                                          author: user,
                                          filesize: 1024,
                                          content_type: "image/png",
                                          digest: "")
  end

  it "names the file the way it will be stored" do
    expect(attachment.filename).to eq("Screen_Shot.png")
  end
end
