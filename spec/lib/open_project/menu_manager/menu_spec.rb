require 'spec_helper'

describe Redmine::MenuManager::Menu do
  let(:menu) { Redmine::MenuManager::Menu.new(:my_menu) }

  describe :find_item do
    let(:item) { item = double('item', :name => 'lorem') }

    before do
      menu << item
    end

    it "should find an item by it's name" do
      menu.find_item(item.name).should == item
    end

    it "should not find an item if the name is wrong" do
      menu.find_item("wrong #{item.name}").should be_nil
    end
  end
end
