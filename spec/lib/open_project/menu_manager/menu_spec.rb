require 'spec_helper'

describe Redmine::MenuManager::Menu do
  let(:menu) { Redmine::MenuManager::Menu.new(:my_menu) }
  let(:item) { Redmine::MenuManager::MenuItem.new(:lorem, Proc.new {}, Proc.new {}) }
  let(:item2) { Redmine::MenuManager::MenuItem.new(:lorem2, Proc.new {}, Proc.new {}) }
  let(:item3) { Redmine::MenuManager::MenuItem.new(:lorem3, Proc.new {}, Proc.new {}) }

  describe :find_item do
    before do
      menu.add(item)
    end

    it "should find an item by it's name" do
      menu.find_item(item.name).should == item
    end

    it "should not find an item if the name is wrong" do
      menu.find_item("wrong #{item.name}").should be_nil
    end
  end

  describe :place do
    it "should place a new item as it's child if nothing is specified" do
      menu.place(item)

      menu.children.should == [item]
    end

    it "should place a new item as a parent's child if such is referenced by name" do
      menu.place(item)
      menu.place(item2, :parent => item.name)

      item.children.should == [item2]
    end

    it "should place a new item at the beginning of a parent's children if first is true" do
      menu.place(item)
      menu.place(item2, :first => true)

      menu.children.should == [item2, item]
    end

    it "should place a new item before the parent's child with the provided name" do
      menu.place(item)
      menu.place(item2)
      menu.place(item3, :before => item2.name)

      menu.children.should == [item, item3, item2]
    end

    it "should place a new item after the parent's child with the provided name" do
      menu.place(item)
      menu.place(item2)
      menu.place(item3, :after => item.name)

      menu.children.should == [item, item3, item2]
    end

    it "should place a new item at the end of the parent's children if last is true" do
      menu.place(item3, :last => true)
      menu.place(item)
      menu.place(item2)

      menu.children.should == [item, item2, item3]
    end
  end
end
