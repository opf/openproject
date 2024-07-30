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

RSpec.describe Redmine::MenuManager::Mapper do
  let(:mapper) { described_class.new(:test_menu, {}) }

  shared_context "with a single node pushed to root" do
    before do
      mapper.push :test_item, { controller: "foo", action: "bar" }, {}
    end
  end

  shared_context "with a node with a child" do
    before do
      mapper.push :test_parent_item, { controller: "foo", action: "bar" }, {}
      mapper.push :test_child_item, { controller: "foo", action: "bar" }, parent: :test_parent_item
    end
  end

  describe "#exists?" do
    include_context "with a single node pushed to root" do
      it "the pushed node does exist" do
        expect(mapper)
          .to exist(:test_item)
      end

      it "a different node does not exist" do
        expect(mapper)
          .not_to exist(:not_pushed)
      end
    end

    include_context "with a node with a child" do
      it "the pushed node does exist" do
        expect(mapper)
          .to exist(:test_child_item)
      end
    end
  end

  describe "#find" do
    include_context "with a single node pushed to root" do
      it "finds the pushed node" do
        expect(mapper.find(:test_item))
          .to be_a(Redmine::MenuManager::MenuItem)
      end

      it "does not find a non pushed node" do
        expect(mapper.find(:not_pushed))
          .to be_nil
      end

      it "does not find a deleted node" do
        mapper.delete(:test_item)

        expect(mapper.find(:test_item))
          .to be_nil
      end
    end

    include_context "with a node with a child" do
      it "finds the pushed child node" do
        expect(mapper.find(:test_child_item))
          .to be_a(Redmine::MenuManager::MenuItem)
      end
    end
  end

  describe "#delete" do
    include_context "with a single node pushed to root" do
      it "returns the deleted node" do
        expect(mapper.delete(:test_item))
          .to be_a(Redmine::MenuManager::MenuItem)
      end

      it "does not bail on a non existing node" do
        expect { mapper.delete(:not_pushed) }
          .not_to raise_error
      end

      it "returns nil for a non existing node" do
        expect(mapper.delete(:not_pushed))
          .to be_nil
      end
    end
  end

  describe "#children order of the pushed elements" do
    shared_examples_for "items in the expected order" do
      it "has the items in the expected order" do
        expect(mapper.find(:root).children.map(&:name))
          .to eq %i[
            test_first
            test_second
            test_third
            test_fourth
            test_fifth
          ]
      end
    end

    context "for items without any special order options" do
      before do
        mapper.push :test_first, { controller: "foo", action: "bar" }, {}
        mapper.push :test_second, { controller: "foo", action: "bar" }, {}
        mapper.push :test_third, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fourth, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fifth, { controller: "foo", action: "bar" }, {}
      end

      it_behaves_like "items in the expected order"
    end

    context "for items with a first options" do
      before do
        mapper.push :test_second, { controller: "foo", action: "bar" }, {}
        mapper.push :test_third, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fourth, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fifth, { controller: "foo", action: "bar" }, {}
        mapper.push :test_first, { controller: "foo", action: "bar" }, { first: true }
      end

      it_behaves_like "items in the expected order"
    end

    context "for items with a last options" do
      before do
        mapper.push :test_first, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fifth, { controller: "foo", action: "bar" }, { last: true }
        mapper.push :test_second, { controller: "foo", action: "bar" }, {}
        mapper.push :test_third, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fourth, { controller: "foo", action: "bar" }, {}
      end

      it_behaves_like "items in the expected order"
    end

    context "for items with a before options" do
      before do
        mapper.push :test_first, { controller: "foo", action: "bar" }, {}
        mapper.push :test_second, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fourth, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fifth, { controller: "foo", action: "bar" }, {}
        mapper.push :test_third, { controller: "foo", action: "bar" }, { before: :test_fourth }
      end

      it_behaves_like "items in the expected order"
    end

    context "for items with a after options" do
      before do
        mapper.push :test_first, { controller: "foo", action: "bar" }, {}
        mapper.push :test_second, { controller: "foo", action: "bar" }, {}
        mapper.push :test_third, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fifth, { controller: "foo", action: "bar" }, {}
        mapper.push :test_fourth, { controller: "foo", action: "bar" }, { after: :test_third }
      end

      it_behaves_like "items in the expected order"
    end
  end

  describe "#url of the pushed element" do
    include_context "with a single node pushed to root" do
      it "is the pushed controller/action pair" do
        expect(mapper.find(:test_item).url)
          .to eq(controller: "foo", action: "bar")
      end
    end
  end
end
