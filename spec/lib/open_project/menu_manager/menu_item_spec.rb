require 'spec_helper'

describe Redmine::MenuManager::MenuItem do
  let(:name) { valid_attributes[0] }
  let(:url) { valid_attributes[1] }
  let(:options) { valid_attributes[2] }
  let(:valid_attributes) { ["MenuNode1", { :controller => :"/issues", :action => :index }, {}] }
  let(:klass) { Redmine::MenuManager::MenuItem }

  describe "name" do
    it "should be the provided name as a symbol" do
      instance = klass.new(*valid_attributes)

      instance.name.should == name.to_sym
    end
  end

  describe "label" do
    it "should return the result of the provided block" do
      expected_return = "lorem ipsum"

      valid_attributes[1] = Proc.new { |x| expected_return }

      instance = klass.new(*valid_attributes)

      instance.label.should == expected_return
    end
  end

  describe "allowed?" do
    it "should return the result of the provided block" do
      options[:if] = Proc.new { true }

      instance = klass.new(*valid_attributes)

      instance.allowed?.should be_true
    end
  end

#  describe "url" do
#    it "should be the provided url" do
#      instance = klass.new(*valid_attributes)
#
#      instance.url.should == url
#    end
#  end
#
#  describe "param" do
#    it "should be :id if nothing was provided" do
#      instance = klass.new(*valid_attributes)
#
#      instance.param.should == :id
#    end
#
#    it "should be whatever is provided" do
#      options[:param] = :project_id
#
#      instance = klass.new(*valid_attributes)
#
#      instance.param.should == :project_id
#    end
#  end
#
#  describe "condition" do
#    it "should be the provided proc" do
#      options[:if] = Proc.new { true }
#
#      instance = klass.new(*valid_attributes)
#
#      instance.condition.should == options[:if]
#    end
#
#    it "should raise ArgumentError if not a proc" do
#      options[:if] = "invalid"
#
#      lambda { klass.new(*valid_attributes) }.should raise_exception(ArgumentError)
#    end
#  end
#
#  describe "html_options" do
#    it "should have a default class if nothing is provided" do
#      instance = klass.new(*valid_attributes)
#
#      instance.html_options.should == { :class => "#{name} ellipsis" }
#    end
#
#    it "should be the provided hash with \"#{name} ellipsis\" appended to the class" do
#      options[:html] = { :class => "blubs", :id => "blubs" }
#
#      instance = klass.new(*valid_attributes)
#
#      instance.html_options.should == { :class => "blubs #{name} ellipsis", :id => "blubs" }
#    end
#
#    it "should raise ArgumentError if not a hash" do
#      options[:html] = "invalid"
#
#      lambda { klass.new(*valid_attributes) }.should raise_exception(ArgumentError)
#    end
#  end
#
#  describe "parent" do
#    it "should be nil regardless of what is provided on initalization" do
#      options[:parent] = "blubs"
#
#      instance = klass.new(*valid_attributes)
#
#      # this might be surprising but is done by rubytree
#      # will have to check whether setting the parent should be removed in the initializer
#      # altogether
#      instance.parent.should == nil
#    end
#
#    it "should raise ArgumentError if self as noted by name" do
#      options[:parent] = name.to_sym
#
#      lambda { klass.new(*valid_attributes) }.should raise_exception(ArgumentError)
#    end
#  end
#
#  describe "child_menus" do
#    it "should be the provided Proc" do
#      options[:children] = Proc.new { true }
#
#      instance = klass.new(*valid_attributes)
#
#      instance.child_menus.should == options[:children]
#    end
#
#    it "should raise ArgumentError if nothing callable is provided" do
#      options[:children] = "blubs"
#
#      lambda { klass.new(*valid_attributes) }.should raise_exception(ArgumentError)
#    end
#  end
#
#  describe "last" do
#    it "should be the provided boolean" do
#      options[:last] = true
#
#      instance = klass.new(*valid_attributes)
#
#      instance.last.should == true
#    end
#
#    it "should be false if nothing is provided" do
#      instance = klass.new(*valid_attributes)
#
#      instance.last.should == false
#    end
#  end
#
#  describe "block" do
#    it "should be the provided block" do
#      block = Proc.new { "" }
#
#      valid_attributes[1] = block
#
#      instance = klass.new(*valid_attributes)
#
#      instance.block.should == block
#    end
#  end
end
