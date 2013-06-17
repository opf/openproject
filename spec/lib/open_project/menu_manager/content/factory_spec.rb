#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'

describe Redmine::MenuManager::Content::Factory do
  let(:klass) { Redmine::MenuManager::Content::Factory }

  describe "build" do
    it "should return a link content when a hash is provided" do
      url = { :one => "1", :two => "2" }
      options = { :a => "1", :b => "2" }

      new_content = double("new_content")

      Redmine::MenuManager::Content::Link.stub!(:new).with(url, options).and_return(new_content)

      klass.build(url, options).should == new_content
    end

    it "should return a link content when a symbol is provided" do
      url = :home_path
      options = {}

      new_content = double("new_content")

      Redmine::MenuManager::Content::Link.stub!(:new).with(url, options).and_return(new_content)

      klass.build(url, options).should == new_content
    end

    it "should return a link content when a url is provided" do
      url = "https://www.openproject.org/projects/support"
      options = {}

      new_content = double("new_content")

      Redmine::MenuManager::Content::Link.stub!(:new).with(url, options).and_return(new_content)

      klass.build(url, options).should == new_content
    end

    it "should return whatever is provided when it has a call method" do
      block = Proc.new { true }

      klass.build(block).should == block
    end

    it "should raise a warning when it does not know what to do" do
      expect { klass.build("blubs") }.to raise_error
    end
  end
end
