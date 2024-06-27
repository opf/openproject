#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe OpenProject::Acts::RegistryMethods do
  def described_module = described_class

  let(:registry) { Class.new.tap { |c| c.extend described_module } }
  let(:acts_as_dummy) { Module.new }
  let(:instance_methods_module) { Module.new }
  let(:model) { Class.new }

  before do
    allow(registry).to receive_messages(module_parent: acts_as_dummy, module_parent_name: "OpenProject::Acts::Dummy")
    allow(acts_as_dummy).to receive(:const_get).with(:InstanceMethods).and_return(instance_methods_module)

    allow(model).to receive(:name).and_return("Model")
  end

  describe ".add" do
    it "allows adding class including instance methods module" do
      model.include instance_methods_module

      expect { registry.add(model) }.not_to raise_error
    end

    it "forbids adding class not including instance methods module" do
      expect { registry.add(model) }.to raise_error(/does not include acts_as_dummy/)
    end
  end

  describe ".instance" do
    before do
      model.include instance_methods_module

      allow(ActiveSupport::Inflector).to receive(:constantize).with("Model").and_return(model)
    end

    it "returns nil for non registered model" do
      expect(registry.instance("models")).to be_nil
    end

    it "returns model class for registered model" do
      registry.add(model)

      expect(registry.instance("models")).to eq(model)
    end
  end
end
