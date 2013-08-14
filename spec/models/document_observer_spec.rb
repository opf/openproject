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
require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentObserver do


  let(:user)      { FactoryGirl.create(:user, firstname: 'Test', lastname: "User", :mail => 'test@test.com') }
  let(:project)   { FactoryGirl.create(:project, name: "TestProject")}

  let(:mail)      do
    mock = Object.new
    mock.stub(:deliver)
    mock
  end


  it "is triggered, when a document has been created" do
    document = FactoryGirl.build(:document)
    #observers are singletons, so any_instance exactly leaves out the singleton
    DocumentObserver.instance.should_receive(:after_create)
    document.save!
  end

  it "calls the DocumentsMailer, when a new document has been added" do
    document = FactoryGirl.build(:document)
    # make sure, that we have actually someone to notify
    document.stub(:recipients).and_return(user.mail)
    # ... and notifies are actually sent out
    Notifier.stub(:notify?).and_return(true)

    DocumentsMailer.should_receive(:document_added).and_return(mail)

    document.save
  end


end