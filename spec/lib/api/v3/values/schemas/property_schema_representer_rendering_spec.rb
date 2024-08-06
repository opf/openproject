# --copyright
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
# ++

require "spec_helper"

RSpec.describe API::V3::Values::Schemas::PropertySchemaRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }

  let(:self_link) { "/a/self/link" }

  let(:model) do
    API::V3::Values::Schemas::Model
      .new("The start date to that object",
           "ADate")
  end

  let(:representer) do
    described_class.create(model,
                           self_link:,
                           current_user:)
  end

  subject(:generated) { representer.to_json }

  describe "_type" do
    it "is indicated as Schema" do
      expect(subject)
        .to be_json_eql("Schema".to_json)
              .at_path("_type")
    end
  end

  describe "property" do
    let(:path) { "property" }

    it_behaves_like "has basic schema properties" do
      let(:type) { "String" }
      let(:name) { I18n.t(:"api_v3.attributes.property") }
      let(:required) { true }
      let(:writable) { false }
    end
  end

  describe "value" do
    let(:path) { "value" }

    it_behaves_like "has basic schema properties" do
      let(:type) { model.type }
      let(:name) { model.name }
      let(:required) { true }
      let(:writable) { false }
    end
  end

  describe "_links" do
    describe "self" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { self_link }
      end
    end
  end
end
