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
require "roar/decorator"

RSpec.describe OpenProject::Plugins::ActsAsOpEngine do
  class ActsAsOpEngineTestEngine < Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine
  end

  subject(:engine) { ActsAsOpEngineTestEngine }

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:patches) }
  it { is_expected.to respond_to(:assets) }
  it { is_expected.to respond_to(:additional_permitted_attributes) }
  it { is_expected.to respond_to(:register) }

  describe "#name" do
    subject { engine.name }

    it { is_expected.to eq "ActsAsOpEngineTestEngine" }
  end

  describe "#extend_api_response" do
    let(:parent_representer) do
      Class.new(Roar::Decorator) do
        include Roar::JSON

        property :original
      end
    end
    let!(:loaded_child_representer) { Class.new(parent_representer) }

    def property_names(representer)
      representer.representable_attrs.keys
    end

    before do
      stub_const("API::V3::ActsAsOpEngineTest::ParentRepresenter", parent_representer)
      allow(engine.config).to receive(:to_prepare).and_yield

      engine.extend_api_response(:v3, :acts_as_op_engine_test, :parent) do
        property :added
      end
    end

    it "adds the definitions to the extended representer" do
      expect(property_names(parent_representer)).to include("original", "added")
    end

    it "adds the definitions to subclasses loaded before the extension" do
      expect(property_names(loaded_child_representer)).to include("original", "added")
    end

    it "adds the definitions to subclasses loaded after the extension" do
      expect(property_names(Class.new(parent_representer))).to include("original", "added")
    end
  end
end
