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

RSpec.describe Attachments::ImportCreateService do
  subject(:service) { described_class.new(user:, contract_class: EmptyContract) }

  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }
  let(:file) { FileHelpers.mock_uploaded_file(name: "picture.png", content_type: "image/png") }

  it "creates the attachment on the container" do
    call = service.call(container: work_package, filename: "picture.png", file:)

    expect(call).to be_success
    expect(work_package.attachments.reload.map(&:filename)).to eq(["picture.png"])
  end

  it "does not journalize the container" do
    expect { service.call(container: work_package, filename: "picture.png", file:) }
      .not_to change { work_package.journals.reload.count }
  end

  it "does not touch the container" do
    expect { service.call(container: work_package, filename: "picture.png", file:) }
      .not_to change { work_package.reload.updated_at }
  end
end
