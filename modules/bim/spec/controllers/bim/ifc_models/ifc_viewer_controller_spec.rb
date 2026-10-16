# frozen_string_literal: true

# -- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require_relative "../../../spec_helper"

RSpec.describe Bim::IfcModels::IfcViewerController do
  describe "#parse_showing_models" do
    let(:model) { build_stubbed(:ifc_model) }
    let(:params) { {} }

    before do
      allow(controller).to receive(:params).and_return(params)
      controller.instance_variable_set(:@ifc_models, [model])
      controller.send(:parse_showing_models)
    end

    it "shows no models when the parameter is absent" do
      expect(controller.instance_variable_get(:@shown_model_ids)).to eq([])
      expect(controller.instance_variable_get(:@shown_ifc_models)).to eq([])
    end

    context "when model IDs are provided" do
      let(:params) { { models: [model.id].to_json } }

      it "selects the matching models" do
        expect(controller.instance_variable_get(:@shown_model_ids)).to eq([model.id])
        expect(controller.instance_variable_get(:@shown_ifc_models)).to eq([model])
      end
    end
  end
end
