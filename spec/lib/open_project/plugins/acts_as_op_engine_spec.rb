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

  describe "#include_module" do
    let(:including_classes) { [] }
    let(:mixin) do
      tracked = including_classes

      Module.new do
        define_singleton_method(:included) { |base| tracked << base }
      end
    end
    let(:target_class) { Class.new }
    let(:other_target_class) { Class.new }

    before do
      stub_const("ActsAsOpEngineTest::Mixin", mixin)
      stub_const("ActsAsOpEngineTest::Target", target_class)
      stub_const("ActsAsOpEngineTest::OtherTarget", other_target_class)
      allow(engine.config).to receive(:to_prepare).and_yield
    end

    it "includes the module into all given classes" do
      engine.include_module("ActsAsOpEngineTest::Mixin",
                            into: %w[ActsAsOpEngineTest::Target ActsAsOpEngineTest::OtherTarget])

      expect(target_class).to include(mixin)
      expect(other_target_class).to include(mixin)
    end

    it "accepts a single class name" do
      engine.include_module("ActsAsOpEngineTest::Mixin", into: "ActsAsOpEngineTest::Target")

      expect(target_class).to include(mixin)
    end

    it "does not include the module again when it is already included" do
      2.times { engine.include_module("ActsAsOpEngineTest::Mixin", into: "ActsAsOpEngineTest::Target") }

      expect(including_classes).to eq([target_class])
    end
  end

  describe "#prepend_module" do
    let(:prepending_classes) { [] }
    let(:mixin) do
      tracked = prepending_classes

      Module.new do
        define_singleton_method(:prepended) { |base| tracked << base }

        def greeting = "#{super} from the mixin"
      end
    end
    let(:target_class) do
      Class.new do
        def greeting = "hello"
      end
    end
    let(:other_target_class) { Class.new }

    before do
      stub_const("ActsAsOpEngineTest::Mixin", mixin)
      stub_const("ActsAsOpEngineTest::Target", target_class)
      stub_const("ActsAsOpEngineTest::OtherTarget", other_target_class)
      allow(engine.config).to receive(:to_prepare).and_yield
    end

    it "prepends the module to all given classes" do
      engine.prepend_module("ActsAsOpEngineTest::Mixin",
                            into: %w[ActsAsOpEngineTest::Target ActsAsOpEngineTest::OtherTarget])

      expect(target_class.ancestors.first).to eq(mixin)
      expect(other_target_class.ancestors.first).to eq(mixin)
    end

    it "overrides the methods of the class" do
      engine.prepend_module("ActsAsOpEngineTest::Mixin", into: "ActsAsOpEngineTest::Target")

      expect(target_class.new.greeting).to eq("hello from the mixin")
    end

    it "does not prepend the module again when it is already prepended" do
      2.times { engine.prepend_module("ActsAsOpEngineTest::Mixin", into: "ActsAsOpEngineTest::Target") }

      expect(prepending_classes).to eq([target_class])
    end
  end

  describe "#prepend_class_methods" do
    let(:prepending_classes) { [] }
    let(:mixin) do
      tracked = prepending_classes

      Module.new do
        define_singleton_method(:prepended) { |base| tracked << base }

        def greeting = "#{super} from the mixin"
      end
    end
    let(:target_class) do
      Class.new do
        def self.greeting = "hello"
      end
    end
    let(:other_target_class) { Class.new }

    before do
      stub_const("ActsAsOpEngineTest::Mixin", mixin)
      stub_const("ActsAsOpEngineTest::Target", target_class)
      stub_const("ActsAsOpEngineTest::OtherTarget", other_target_class)
      allow(engine.config).to receive(:to_prepare).and_yield
    end

    it "prepends the module to the singleton classes of all given classes" do
      engine.prepend_class_methods("ActsAsOpEngineTest::Mixin",
                                   into: %w[ActsAsOpEngineTest::Target ActsAsOpEngineTest::OtherTarget])

      expect(target_class.singleton_class.ancestors.first).to eq(mixin)
      expect(other_target_class.singleton_class.ancestors.first).to eq(mixin)
    end

    it "overrides the class methods of the class" do
      engine.prepend_class_methods("ActsAsOpEngineTest::Mixin", into: "ActsAsOpEngineTest::Target")

      expect(target_class.greeting).to eq("hello from the mixin")
    end

    it "does not add the methods to instances of the class" do
      engine.prepend_class_methods("ActsAsOpEngineTest::Mixin", into: "ActsAsOpEngineTest::Target")

      expect(target_class.new).not_to respond_to(:greeting)
    end

    it "does not prepend the module again when it is already prepended" do
      2.times { engine.prepend_class_methods("ActsAsOpEngineTest::Mixin", into: "ActsAsOpEngineTest::Target") }

      expect(prepending_classes).to eq([target_class.singleton_class])
    end
  end
end
