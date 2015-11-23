#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe DocumentsController do

  render_views

  let(:admin)           { FactoryGirl.create(:admin)}
  let(:project)         { FactoryGirl.create(:project, name: "Test Project")}
  let(:user)            { FactoryGirl.create(:user)}
  let(:role)            { FactoryGirl.create(:role, permissions: [:view_documents]) }

  let(:default_category){
    FactoryGirl.create(:document_category, project: project, name: "Default Category")
  }

  before do
    allow(User).to receive(:current).and_return admin
  end

  describe "index" do

    let(:document) {
      FactoryGirl.create(:document, title: "Sample Document", project: project, category: default_category)
    }

    before do
      document.update_attributes(description:<<LOREM)
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut egestas, mi vehicula varius varius, ipsum massa fermentum orci, eget tristique ante sem vel mi. Nulla facilisi. Donec enim libero, luctus ac sagittis sit amet, vehicula sagittis magna. Duis ultrices molestie ante, eget scelerisque sem iaculis vitae. Etiam fermentum mauris vitae metus pharetra condimentum fermentum est pretium. Proin sollicitudin elementum quam quis pharetra.  Aenean facilisis nunc quis elit volutpat mollis. Aenean eleifend varius euismod. Ut dolor est, congue eget dapibus eget, elementum eu odio. Integer et lectus neque, nec scelerisque nisi. EndOfLineHere

Vestibulum non velit mi. Aliquam scelerisque libero ut nulla fringilla a sollicitudin magna rhoncus.  Praesent a nunc lorem, ac porttitor eros. Sed ac diam nec neque interdum adipiscing quis quis justo. Donec arcu nunc, fringilla eu dictum at, venenatis ac sem. Vestibulum quis elit urna, ac mattis sapien. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
LOREM

      get :index, project_id: project.identifier
    end

    it "should render the index-template successfully" do
      expect(response).to be_success
      expect(response).to render_template("index")
    end

    it "should group documents by category, if no other sorting is given " do
      expect(assigns(:grouped)).not_to be_nil
      expect(assigns(:grouped).keys.map(&:name)).to eql [default_category.name]
    end

    it "should render documents with long descriptions properly" do

      expect(response.body).to have_css('.wiki p')
      expect(response.body).to have_css('.wiki p', text: (document.description.split("\n").first + '...'))
      expect(response.body).to have_css('.wiki p', text: /EndOfLineHere.../)
    end

  end

  describe 'new' do
    before do
      get :new, project_id: project.id
    end

    it 'show the new document form' do
      expect(response).to render_template(partial: 'documents/_form')
    end
  end

  describe "create" do

    let(:document_attributes) {
      FactoryGirl.attributes_for(:document, title: "New Document",
                                            project_id: project.id,
                                            category_id: default_category.id)
    }


    before do
      ActionMailer::Base.deliveries.clear
      allow(Setting).to receive(:notified_events).and_return(Setting.notified_events.dup << 'document_added')
    end

    it "should create a new document with valid arguments" do
      expect do
        post :create, project_id: project.identifier,
                      document: FactoryGirl.attributes_for(:document, title: "New Document",
                                                                      project_id: project.id,
                                                                      category_id: default_category.id
                                                          )

      end.to change{Document.count}.by 1
    end

    it "should create a new document with valid arguments" do
      expect do
        post :create,
             project_id: project.identifier,
             document: document_attributes
      end.to change{Document.count}.by 1
    end

    describe "with attachments" do

      before do
        notify_project = project
        FactoryGirl.create(:member, project: notify_project, user: user, roles: [role])

        post :create,
             project_id: notify_project.identifier,
             document: FactoryGirl.attributes_for(:document,  title: "New Document",
                                                              project_id: notify_project.id,
                                                              category_id: default_category.id
                                                 ),
             attachments: { '1' => { description: "sample file", file: file_attachment } }
      end

      it "should add an attachment" do
        document = Document.last

        expect(document.attachments.count).to eql 1
        attachment = document.attachments.first
        expect(attachment.description).to eql "sample file"
        expect(attachment.filename).to eql "testfile.txt"
      end

      it "should redirect to the documents-page" do
        expect(response).to redirect_to project_documents_path(project.identifier)
      end

      it "should send out mails with notifications to members of the project with :view_documents-permission" do
        expect(ActionMailer::Base.deliveries.size).to eql 1
      end
    end
  end

  describe "destroy" do

    let(:document) {
      FactoryGirl.create(:document, title: "Sample Document", project: project, category: default_category)
    }

    before do
      document
    end

    it "should delete the document and redirect back to documents-page of the project" do
      expect{
        delete :destroy, id: document.id
      }.to change{Document.count}.by -1

      expect(response).to redirect_to "/projects/#{project.identifier}/documents"
      expect{Document.find(document.id)}.to raise_error ActiveRecord::RecordNotFound
    end
  end

  def file_attachment
    test_document = "#{OpenProject::Documents::Engine.root}/spec/assets/attachments/testfile.txt"
    Rack::Test::UploadedFile.new(test_document, "text/plain")
  end
end
