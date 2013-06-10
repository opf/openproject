require 'spec_helper'

describe Redmine::MenuManager::Mapper do
  let(:root) { double('root') }
  let(:items) { {} }
  let(:mapper) { Redmine::MenuManager::Mapper.new(:lorem, items) }

  describe :push do
    it "should allow pushing on root" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}

      mapper.exists?(:test_overview).should be_true
    end

    describe "a menu item with a block for contents" do
      let(:block) { Proc.new { "" } }
      let(:name) { :test }

      it "should create the item" do
        root = double(Redmine::MenuManager::TreeNode)
        container = double(Redmine::MenuManager::TreeNode, :root => root)

        mapper = Redmine::MenuManager::Mapper.new(:lorem, { :lorem => container })

        node = double(Redmine::MenuManager::MenuItem, name: name)

        Redmine::MenuManager::MenuItem.should_receive(:new).with(name, block, {}) do
          node
        end

        root.should_receive(:add).with(node)

        mapper.push name, block
      end
    end

    it "should allow pushing onto parent" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_child, { :controller => 'projects', :action => 'show'}, {:parent => :test_overview}

      mapper.exists?(:test_child).should be_true

      mapper.find(:test_child).name.should == :test_child
    end

    it "should allow pushing onto grandparent" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_child, { :controller => 'projects', :action => 'show'}, {:parent => :test_overview}
      mapper.push :test_grandchild, { :controller => 'projects', :action => 'show'}, {:parent => :test_child}

      mapper.exists?(:test_grandchild).should be_true

      grandchild = mapper.find(:test_grandchild)

      grandchild.name.should == :test_grandchild
      grandchild.parent.name.should == :test_child
    end

    it "should allow pushing as first" do
      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {:first => true}

      root = mapper.find(:root)
      root.children.size.should == 5

      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|

        root.children[position].should_not be_nil
        root.children[position].name.should == name
      end
    end

    it "should allow pushing before" do
      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {:before => :test_fourth}

      root = mapper.find(:root)

      root.children.size.should == 5

      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|
        root.children[position].should_not be_nil
        root.children[position].name.should == name
      end

    end

    it "should allow pushing after" do
      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {:after => :test_third}

      root = mapper.find(:root)

      root.children.size.should == 5

      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|
        root.children[position].should_not be_nil
        root.children[position].name.should == name
      end

    end

    it "should allow pushing to the back with last" do
      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {:last => true}
      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {}

      root = mapper.find(:root)

      root.children.size.should == 5

      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|
        root.children[position].should_not be_nil
        root.children[position].name.should == name
      end
    end

    it "should allow pushing a child node" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
      mapper.push :test_child, { :controller => 'projects', :action => 'show'}, {:parent => :test_overview }

      mapper.exists?(:test_child).should be_true
    end

    it "should not create an invalid node" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}

      mapper.exists?(:test_child).should be_false
    end
  end

  describe :find do
    it "should find a pushed node" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}

      item = mapper.find(:test_overview)

      item.name.should == :test_overview
      item.url.should == {:controller => 'projects', :action => 'show'}
    end

    it "should find nil when looking for a non pushed node" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}

      mapper.find(:nothing).should be_nil
    end
  end

  describe :delete do
    it "should delete a node" do
      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}

      mapper.delete(:test_overview).should_not be_nil

      mapper.find(:test_overview).should be_nil
    end

    it "should return nil if a non existing node is to be deleted" do
      mapper.delete(:test_overview).should be_nil
    end

    it "should allow pushing after deletion" do
      mapper.push :not_last, Redmine::Info.help_url
      mapper.push :administration, { :controller => 'projects', :action => 'show'}, {:last => true}
      mapper.push :help, Redmine::Info.help_url, :last => true

      lambda do
        mapper.delete(:administration)
        mapper.delete(:help)

        mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
      end.should_not raise_error
    end
  end
end
