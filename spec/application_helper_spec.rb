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

describe ApplicationHelper do
  include ApplicationHelper
  include ActionView::Helpers
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers


  describe ".textilizable" do
    let(:project) { FactoryGirl.create :valid_project }
    let(:identifier) { project.identifier }
    let(:project_member) { FactoryGirl.create :user,
                                              :member_in_project => project,
                                              :member_through_role => FactoryGirl.create(:role,
                                                                                         :permissions => [:view_work_packages, :edit_work_packages,
                                                                                         :view_documents, :browse_repository, :view_changesets, :view_wiki_pages]) }
    let(:document) { FactoryGirl.create :document,
                                          :title => 'Test document',
                                          :project => project }

    before do
      @project = project
      User.stubs(:current).returns(project_member)
    end

    after do
      User.unstub(:current)
    end

    context "Simple Document links" do
      let(:document_link) { link_to('Test document',
                                     {:controller => 'documents', :action => 'show', :id => document.id},
                                     :class => 'document') }

      context "Plain link" do
        subject { textilizable("document##{document.id}") }

        it { should eq("<p>#{document_link}</p>") }
      end

      context "Link with document name" do
        subject { textilizable("document##{document.id}") }

        it { should eq("<p>#{document_link}</p>") }
      end

      context "Escaping plain link" do
        subject { textilizable("!document##{document.id}") }

        it { should eq("<p>document##{document.id}</p>") }
      end

      context "Escaping link with document name" do
        subject { textilizable('!document:"Test document"') }

        it { should eq('<p>document:"Test document"</p>') }
      end
    end

    context 'Cross-Project Document Links' do
      let(:the_other_project) { FactoryGirl.create :valid_project }

      context "By name without project" do
        subject { textilizable("document:\"#{document.title}\"", :project => the_other_project) }

        it { should eq('<p>document:"Test document"</p>') }
      end

      context "By id and given project" do
        subject { textilizable("#{identifier}:document##{document.id}", :project => the_other_project) }

        it { should eq("<p><a href=\"/documents/#{document.id}\" class=\"document\">Test document</a></p>") }
      end

      context "By name and given project" do
        subject { textilizable("#{identifier}:document:\"#{document.title}\"", :project => the_other_project) }

        it { should eq("<p><a href=\"/documents/#{document.id}\" class=\"document\">Test document</a></p>") }
      end

      context "Invalid link" do
        subject { textilizable("invalid:document:\"Test document\"", :project => the_other_project) }

        it { should eq('<p>invalid:document:"Test document"</p>') }
      end
    end
  end
end
