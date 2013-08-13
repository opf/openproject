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

describe DocumentsMailer do

  let(:user)      { FactoryGirl.create(:user, firstname: 'Test', lastname: "User", :mail => 'test@test.com') }
  let(:project)   { FactoryGirl.create(:project, name: "TestProject")}
  let(:document)  { FactoryGirl.create(:document, project: project, description: "Test Description", title: "Test Title" )}
  let(:mail)      { DocumentsMailer.document_added(user, document) }


  describe "document added-mail" do
    it "renders the subject" do
      expect(mail.subject).to eql '[TestProject] New document: Test Title'
    end

    it "should render the receivers mail" do
      expect(mail.to.count).to eql 1
      expect(mail.to.first).to eql user.mail
    end

    it "should render the document-info into the body" do
      expect(mail.body.encoded).to match(document.description)
      expect(mail.body.encoded).to match(document.title)
    end

  end




end
