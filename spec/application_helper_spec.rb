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
  include WorkPackagesHelper
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
    let(:issue) { FactoryGirl.create :issue,
                                     :project => project,
                                     :author => project_member,
                                     :type => project.types.first }

    before do
      @project = project

      User.stubs(:current).returns(project_member)

      Setting.enabled_scm = Setting.enabled_scm << "Filesystem" unless Setting.enabled_scm.include? "Filesystem"
    end

    after do
      User.unstub(:current)

      Setting.enabled_scm.delete "Filesystem"
    end

  context "Document links" do
      let(:document) { FactoryGirl.create :document,
                                          :title => 'Test document',
                                          :project => project }
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
  end
end
