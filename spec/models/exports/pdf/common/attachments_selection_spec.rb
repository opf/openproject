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

RSpec.describe Exports::PDF::Common::Attachments, "selecting embedded attachments", :with_direct_uploads do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages export_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:) }

  let(:png_bytes) { Rails.root.join("spec/fixtures/files/image.png").binread }
  let(:bzip2_bytes) { "BZh91AY&SY".b + ("\x00".b * 64) }

  subject(:export) do
    work_package.update_column(:description, "![](/api/v3/attachments/#{attachment.id}/content)")
    login_as(user)
    WorkPackage::PDFExport::WorkPackageToPdf.new(work_package.reload, {}).export!
  end

  before do
    allow(MiniMagick::Tool).to receive(:new).and_call_original
  end

  def create_attachment(content:, status:, factory: :attachment)
    file = FileHelpers.mock_uploaded_file(name: "image.png", content_type: "image/png", content:, binary: true)
    create(factory, container: work_package, author: user, file:, status:).tap do |attachment|
      attachment.update_columns(content_type: "image/png")
    end
  end

  shared_examples "skips the image" do
    it "exports without processing the image" do
      expect(export.content).to start_with("%PDF")
      expect(MiniMagick::Tool).not_to have_received(:new)
    end
  end

  context "with an unfinished upload of a mismatched stored type" do
    let(:attachment) { create_attachment(factory: :pending_direct_upload, content: bzip2_bytes, status: :prepared) }

    it_behaves_like "skips the image"
  end

  context "with a quarantined image" do
    let(:attachment) { create_attachment(content: png_bytes, status: :quarantined) }

    it_behaves_like "skips the image"
  end

  context "with an image awaiting a scan",
          with_ee: %i[virus_scanning],
          with_settings: { antivirus_scan_mode: :clamav_socket } do
    let(:attachment) { create_attachment(content: png_bytes, status: :uploaded) }

    it_behaves_like "skips the image"
  end

  context "with an uploaded file of a mismatched stored type" do
    let(:attachment) { create_attachment(content: bzip2_bytes, status: :uploaded) }

    it_behaves_like "skips the image"
  end

  context "with an uploaded image" do
    let(:attachment) { create_attachment(content: png_bytes, status: :uploaded) }

    it "processes the image" do
      expect(export.content).to start_with("%PDF")
      expect(MiniMagick::Tool).to have_received(:new).at_least(:once)
    end
  end
end
