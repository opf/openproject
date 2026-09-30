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
require "services/base_services/behaves_like_create_service"

RSpec.describe Bim::IfcModels::CreateService do
  it_behaves_like "BaseServices create service" do
    let(:model_class) { Bim::IfcModels::IfcModel }
    let(:factory) { :ifc_model }
    let(:conversion_job) do
      double("ifc_conversion_job").tap do |job|
        allow(job).to receive(:perform_later)

        stub_const("Bim::IfcModels::IfcConversionJob", job)
      end
    end

    it "queues a conversion job" do
      expect(conversion_job)
        .to(receive(:perform_later))
        .with(model_instance)

      subject
    end

    context "if the SetAttributeService is unsuccessful" do
      let(:set_attributes_success) { false }

      it "queues no conversion job" do
        expect(conversion_job).not_to receive(:perform_later)

        subject
      end
    end

    context "when the model is invalid" do
      let(:model_save_result) { false }

      it "queues no conversion job" do
        expect(conversion_job).not_to receive(:perform_later)

        subject
      end
    end
  end
end
