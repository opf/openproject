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

RSpec.describe Bim::IfcModels::IfcModel do
  subject { described_class.new params }

  let(:params) { { title: "foo", is_default: true } }

  describe "converted?" do
    let(:attachment) { build(:attachment) }

    it "is converted when the xkt attachment is present" do
      expect(subject).not_to be_converted

      allow(subject).to receive(:xkt_attachment).and_return(attachment)

      expect(subject).to be_converted
    end
  end

  describe "ifc_attachment=" do
    let(:project) { create(:project, enabled_module_names: %i[bim]) }
    let(:ifc_attachment) { subject.ifc_attachment }
    let(:new_attachment) do
      FileHelpers.mock_uploaded_file name: "model.ifc", content_type: "application/binary", binary: true
    end

    subject { create(:ifc_model_minimal_converted, project:) }

    current_user do
      create(:user,
             member_with_permissions: { project => %i[manage_ifc_models] })
    end

    it "replaces the previous attachment" do
      expect(ifc_attachment).to be_present
      expect(subject.xkt_attachment).to be_present
      expect(subject).to be_converted

      subject.ifc_attachment = new_attachment
      expect { ifc_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect(subject.ifc_attachment).not_to eq ifc_attachment
      expect(subject.ifc_attachment).to be_present
      expect(subject.xkt_attachment).not_to be_present
      expect(subject).not_to be_converted
    end
  end
end
