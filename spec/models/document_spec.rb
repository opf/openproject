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


describe Document do

  let(:documentation_category) { FactoryGirl.create :document_category, :name => 'User documentation'}
  let(:project)                { FactoryGirl.create :project}
  let(:user)                   { FactoryGirl.create(:user)}
  let(:admin)                  { FactoryGirl.create(:admin)}

  context "validation" do

    it { should validate_presence_of :project}
    it { should validate_presence_of :title}
    it { should validate_presence_of :category}

  end

  describe "create with a valid document" do

    let(:valid_document) {Document.new(title: "Test", project: project, category: documentation_category)}

    it "should add a document" do
      expect{
        valid_document.save
      }.to change{Document.count}.by 1
    end

    it "should send out email-notifications" do
      valid_document.stub(:recipients).and_return([user.mail])
      Notifier.stub(:notify?).with(:document_added).and_return(true)

      expect{
        valid_document.save
      }.to change{ActionMailer::Base.deliveries.size}.by 1

    end

    it "should send notifications to the recipients of the project" do
      project.stub(:notified_users).and_return([admin])
      document = FactoryGirl.create(:document, project: project)

      expect(document.recipients).not_to be_empty
      expect(document.recipients.count).to eql 1
      expect(document.recipients).to include admin.mail
    end

    it "should set a default-category, if none is given" do
      default_category = FactoryGirl.create :document_category, :name => 'Technical documentation', :is_default => true
      document = Document.new(project: project, title: "New Document")
      expect(document.category).to eql default_category
      expect{
        document.save
      }.to change{Document.count}.by 1
    end

    it "with attachments should change the updated_on-date on the document to the attachment's date" do
      3.times do
        FactoryGirl.create(:attachment, container: valid_document)
      end

      valid_document.reload
      expect(valid_document.attachments.size).to eql 3
      expect(valid_document.attachments.map(&:created_on).max).to eql valid_document.updated_on
    end

    it "without attachments, the updated-on-date is taken from the document's date" do
      document = FactoryGirl.create(:document, project: project)
      expect(document.attachments).to be_empty
      expect(document.created_on).to eql document.updated_on
    end
  end

end
