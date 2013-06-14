require 'spec_helper'

describe Redmine::MenuManager::Mapper do
  let(:root) { double('root') }
  let(:items) { {} }
  let(:mapper) { Redmine::MenuManager::Mapper.new(:lorem, items) }

  def should_create_new_item_by_content_and_options content, options
    node = double('new_node')
    factory_content = double("factory_content")
    factory_granter = double("factory_content")

    Redmine::MenuManager::Content::Factory.should_receive(:build)
                                          .with(content, options)
                                          .and_return(factory_content)

    Redmine::MenuManager::Granter::Factory.should_receive(:build)
                                          .with(content, options)
                                          .and_return(factory_granter)

    Redmine::MenuManager::MenuItem.should_receive(:new)
                                  .with(name, factory_content, factory_granter)
                                  .and_return(node)

    node
  end

  describe :push do
    let(:name) { :test }
    let(:root) { double(Redmine::MenuManager::TreeNode) }
    let(:container) { double(Redmine::MenuManager::TreeNode, :root => root) }
    let(:mapper) { Redmine::MenuManager::Mapper.new(:lorem, :lorem => container) }
    let(:contents) { double("contents") }
    let(:options) { { } }
    let(:new_node) { should_create_new_node_by_content_and_options contents, options }

    it "should push a new item onto root if nothing else is specified" do
      new_item = should_create_new_item_by_content_and_options contents, options
      root.should_receive(:add).with(new_item)

      mapper.push name, contents, options
    end

    it "should push a new item onto parent if such is referenced by name" do
      options = { :parent => 'target_parent' }

      target_parent = double('target_parent')
      root.should_receive(:find_item)
          .with(options[:parent])
          .and_return(target_parent)

      new_item = should_create_new_item_by_content_and_options contents, options
      target_parent.should_receive(:add).with(new_item)

      mapper.push name, contents, options
    end

#    it "should allow pushing onto parent" do
#      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_child, { :controller => 'projects', :action => 'show'}, {:parent => :test_overview}
#
#      mapper.exists?(:test_child).should be_true
#
#      mapper.find(:test_child).name.should == :test_child
#    end
#
#    it "should allow pushing onto grandparent" do
#      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_child, { :controller => 'projects', :action => 'show'}, {:parent => :test_overview}
#      mapper.push :test_grandchild, { :controller => 'projects', :action => 'show'}, {:parent => :test_child}
#
#      mapper.exists?(:test_grandchild).should be_true
#
#      grandchild = mapper.find(:test_grandchild)
#
#      grandchild.name.should == :test_grandchild
#      grandchild.parent.name.should == :test_child
#    end
#
#    it "should allow pushing as first" do
#      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {:first => true}
#
#      root = mapper.find(:root)
#      root.children.size.should == 5
#
#      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|
#
#        root.children[position].should_not be_nil
#        root.children[position].name.should == name
#      end
#    end
#
#    it "should allow pushing before" do
#      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {:before => :test_fourth}
#
#      root = mapper.find(:root)
#
#      root.children.size.should == 5
#
#      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|
#        root.children[position].should_not be_nil
#        root.children[position].name.should == name
#      end
#
#    end
#
#    it "should allow pushing after" do
#      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {:after => :test_third}
#
#      root = mapper.find(:root)
#
#      root.children.size.should == 5
#
#      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|
#        root.children[position].should_not be_nil
#        root.children[position].name.should == name
#      end
#
#    end
#
#    it "should allow pushing to the back with last" do
#      mapper.push :test_first, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_second, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_third, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_fifth, { :controller => 'projects', :action => 'show'}, {:last => true}
#      mapper.push :test_fourth, { :controller => 'projects', :action => 'show'}, {}
#
#      root = mapper.find(:root)
#
#      root.children.size.should == 5
#
#      {0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth}.each do |position, name|
#        root.children[position].should_not be_nil
#        root.children[position].name.should == name
#      end
#    end
#
#    it "should allow pushing a child node" do
#      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#      mapper.push :test_child, { :controller => 'projects', :action => 'show'}, {:parent => :test_overview }
#
#      mapper.exists?(:test_child).should be_true
#    end
#
#    it "should not create an invalid node" do
#      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#
#      mapper.exists?(:test_child).should be_false
#    end
#  end
#
#  describe :find do
#    it "should find a pushed node" do
#      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#
#      item = mapper.find(:test_overview)
#
#      item.name.should == :test_overview
##      item.url.should == {:controller => 'projects', :action => 'show'}
#    end
#
#    it "should find nil when looking for a non pushed node" do
#      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#
#      mapper.find(:nothing).should be_nil
#    end
#  end
#
#  describe :delete do
#    it "should delete a node" do
#      mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#
#      mapper.delete(:test_overview).should_not be_nil
#
#      mapper.find(:test_overview).should be_nil
#    end
#
#    it "should return nil if a non existing node is to be deleted" do
#      mapper.delete(:test_overview).should be_nil
#    end
#
#    it "should allow pushing after deletion" do
#      mapper.push :not_last, Redmine::Info.help_url
#      mapper.push :administration, { :controller => 'projects', :action => 'show'}, {:last => true}
#      mapper.push :help, Redmine::Info.help_url, :last => true
#
#      lambda do
#        mapper.delete(:administration)
#        mapper.delete(:help)
#
#        mapper.push :test_overview, { :controller => 'projects', :action => 'show'}, {}
#      end.should_not raise_error
#    end
  end
end
