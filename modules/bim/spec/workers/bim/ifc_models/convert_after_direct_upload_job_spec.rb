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

RSpec.describe Bim::IfcModels::ConvertAfterDirectUploadJob, type: :job do
  let(:ifc_model) { create(:ifc_model) }
  let(:batch) { instance_double(GoodJob::Batch, properties: { ifc_model: }) }

  before do
    allow(ifc_model).to receive(:ifc_attachment).and_return(ifc_attachment)
  end

  context "when the upload has been finished" do
    let(:ifc_attachment) { build_stubbed(:attachment, status: :uploaded) }

    it "enqueues the conversion" do
      described_class.perform_now(batch, {})

      expect(Bim::IfcModels::IfcConversionJob).to have_been_enqueued.with(ifc_model)
    end
  end

  context "when the upload is still pending" do
    let(:ifc_attachment) { build_stubbed(:pending_direct_upload) }

    it "does not enqueue the conversion" do
      described_class.perform_now(batch, {})

      expect(Bim::IfcModels::IfcConversionJob).not_to have_been_enqueued
    end
  end

  context "when finishing the upload removed the attachment" do
    let(:ifc_attachment) { nil }

    it "does not enqueue the conversion" do
      described_class.perform_now(batch, {})

      expect(Bim::IfcModels::IfcConversionJob).not_to have_been_enqueued
    end
  end
end
