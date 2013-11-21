#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe ApplicationHelper do
  include ApplicationHelper
  include WorkPackagesHelper

  describe "format_activity_description" do
    it "truncates given text" do
      text = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lore"
      format_activity_description(text).size.should == 120
    end

    it "replaces escaped line breaks with html line breaks and should be html_safe" do
      text = "Lorem ipsum dolor sit \namet, consetetur sadipscing elitr, sed diam nonumy eirmod\r tempor invidunt"
      text_html = "Lorem ipsum dolor sit <br />amet, consetetur sadipscing elitr, sed diam nonumy eirmod<br /> tempor invidunt"
      format_activity_description(text).should == text_html
      format_activity_description(text).html_safe?.should be_true
    end

    it "escapes potentially harmful code" do
      text = "Lorem ipsum dolor <script>alert('pwnd');</script> tempor invidunt"
      format_activity_description(text).include?("lt;script&gt;alert(&#x27;pwnd&#x27;);&lt;/script&gt;").should be_true
    end
  end

  describe "footer_content" do
    context "no additional footer content" do
      before do
        OpenProject::Footer.content = nil
      end

      it { footer_content.should == I18n.t(:text_powered_by, :link => link_to(OpenProject::Info.app_name, OpenProject::Info.url)) }
    end

    context "string as additional footer content" do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content("openproject","footer")
      end

      it { footer_content.include?(I18n.t(:text_powered_by, :link => link_to(OpenProject::Info.app_name, OpenProject::Info.url))).should be_true  }
      it { footer_content.include?("<span class=\"footer_openproject\">footer</span>").should be_true  }
    end

    context "proc as additional footer content" do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content("openproject",Proc.new{Date.parse(Time.now.to_s)})
      end

      it { footer_content.include?("<span class=\"footer_openproject\">#{Date.parse(Time.now.to_s)}</span>").should be_true  }
    end

    context "proc which returns nothing" do
      before do
        OpenProject::Footer.content = nil
        OpenProject::Footer.add_content("openproject",Proc.new{"footer" if false})
      end

      it { footer_content.include?("<span class=\"footer_openproject\">").should be_false }
    end
  end

  describe ".link_to_if_authorized" do
    let(:project) { FactoryGirl.create :valid_project }
    let(:project_member) { FactoryGirl.create :user,
                                              :member_in_project => project,
                                              :member_through_role => FactoryGirl.create(:role,
                                                                                         :permissions => [:view_work_packages, :edit_work_packages,
                                                                                         :browse_repository, :view_changesets, :view_wiki_pages]) }
    let(:issue) { FactoryGirl.create :work_package,
                                     :project => project,
                                     :author => project_member,
                                     :type => project.types.first }


    context "if user is authorized" do
      before do
        self.should_receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized('link_content', {
                                          :controller => 'issues',
                                          :action => 'show',
                                          :id => issue },
                                        :class => 'fancy_css_class')
      end

      subject { @response }

      it { should match /href/ }

      it { should match /fancy_css_class/ }
    end

    context "if user is unauthorized" do
      before do
        self.should_receive(:authorize_for).and_return(false)
        @response = link_to_if_authorized('link_content', {
                                          :controller => 'issues',
                                          :action => 'show',
                                          :id => issue },
                                        :class => 'fancy_css_class')
      end

      subject { @response }

      it { should be_nil }
    end

    context "allow using the :controller and :action for the target link" do
      before do
        self.should_receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized("By controller/action",
                                         { :controller => 'issues',
                                           :action => 'edit',
                                           :id => issue.id })
      end

      subject { @response }

      it { should match /href/ }
    end
  end

  describe ".textilizable" do
    let(:project) { FactoryGirl.create :valid_project }
    let(:identifier) { project.identifier }
    let(:project_member) { FactoryGirl.create :user,
                                              :member_in_project => project,
                                              :member_through_role => FactoryGirl.create(:role,
                                                                                         :permissions => [:view_work_packages, :edit_work_packages,
                                                                                         :browse_repository, :view_changesets, :view_wiki_pages]) }
    let(:issue) { FactoryGirl.create :work_package,
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

    context "Changeset links" do
      let(:repository) { FactoryGirl.create :repository, :project => project }
      let(:changeset1) { FactoryGirl.create :changeset,
                                            :repository => repository,
                                            :comments => 'My very first commit' }
      let(:changeset2) { FactoryGirl.create :changeset,
                                            :repository => repository,
                                            :comments => 'This commit fixes #1, #2 and references #1 & #3' }
      let(:changeset_link) { link_to("r#{changeset1.revision}",
                                     {:controller => 'repositories', :action => 'revision', :project_id => identifier, :rev => changeset1.revision},
                                     :class => 'changeset', :title => 'My very first commit') }
      let(:changeset_link2) { link_to("r#{changeset2.revision}",
                                      {:controller => 'repositories', :action => 'revision', :project_id => identifier, :rev => changeset2.revision},
                                      :class => 'changeset', :title => 'This commit fixes #1, #2 and references #1 & #3') }

      before do
        project.repository = repository
      end

      context "Single link" do
        subject { textilizable("r#{changeset1.revision}") }

        it { should eq("<p>#{changeset_link}</p>") }
      end

      context "Single link with dot" do
        subject { textilizable("r#{changeset1.revision}.") }

        it { should eq("<p>#{changeset_link}.</p>") }
      end

      context "Two links comma separated" do
        subject { textilizable("r#{changeset1.revision}, r#{changeset2.revision}") }

        it { should eq("<p>#{changeset_link}, #{changeset_link2}</p>") }
      end

      context "Single link comma separated without a space" do
        subject { textilizable("r#{changeset1.revision},r#{changeset2.revision}") }

        it { should eq("<p>#{changeset_link},#{changeset_link2}</p>") }
      end

      context "Escaping" do
        subject { textilizable("!r#{changeset1.id}") }

        it { should eq("<p>r#{changeset1.id}</p>") }
      end
    end

    context "Version link" do
      let(:version) { FactoryGirl.create :version,
                                         :name => '1.0',
                                         :project => project }
      let(:version_link) { link_to('1.0',
                                   {:controller => 'versions', :action => 'show', :id => version.id},
                                   :class => 'version') }

      context "Link with version id" do
        subject { textilizable("version##{version.id}") }

        it { should eq("<p>#{version_link}</p>") }
      end

      context "Link with version" do
        subject { textilizable("version:1.0") }
        it { should eq("<p>#{version_link}</p>") }
      end

      context "Link with quoted version" do
        subject { textilizable('version:"1.0"') }

        it { should eq("<p>#{version_link}</p>") }
      end

      context "Escaping link with version id" do
        subject { textilizable("!version##{version.id}") }

        it { should eq("<p>version##{version.id}</p>") }
      end

      context "Escaping link with version" do
        subject { textilizable("!version:1.0") }

        it { should eq("<p>version:1.0</p>") }
      end

      context "Escaping link with quoted version" do
        subject { textilizable('!version:"1.0"') }

        it { should eq('<p>version:"1.0"</p>') }
      end
    end

    context "Message links" do
      let(:board) { FactoryGirl.create :board, :project => project }
      let(:message1) { FactoryGirl.create :message, :board => board }
      let(:message2) { FactoryGirl.create :message,
                                          :board => board,
                                          :parent => message1 }

      before do
        message1.reload
        @message_url = {:controller => 'messages', :action => 'show', :board_id => board.id, :id => message1.id}
      end

      context "Plain message" do
        subject { textilizable("message##{message1.id}") }

        it { should eq("<p>#{link_to(message1.subject, @message_url, :class => 'message')}</p>") }
      end

      context "Message with parent" do
        subject { textilizable("message##{message2.id}") }

        it { should eq("<p>#{link_to(message2.subject, @message_url.merge(:anchor => "message-#{message2.id}", :r => message2.id), :class => 'message')}</p>") }
      end
    end

    context "Issue links" do
      let(:issue_link) { link_to("##{issue.id}",
                         work_package_path(issue),
                         :class => 'issue work_package status-3 priority-1 created-by-me', :title => "#{issue.subject} (#{issue.status})") }

      context "Plain issue link" do
        subject { textilizable("##{issue.id}, [##{issue.id}], (##{issue.id}) and ##{issue.id}.") }

        it { should eq("<p>#{issue_link}, [#{issue_link}], (#{issue_link}) and #{issue_link}.</p>") }
      end

      context "Plain issue link to non-existing element" do
        subject { textilizable('#0123456789') }

        it { should eq('<p>#0123456789</p>') }
      end

      context "Escaping issue link" do
        subject { textilizable("!##{issue.id}.") }

        it { should eq("<p>##{issue.id}.</p>") }
      end

      context "Cyclic Description Links" do
        let(:issue2) { FactoryGirl.create :work_package,
                                         :project => project,
                                         :author => project_member,
                                         :type => project.types.first }

        before do
          issue2.description = "####{issue.id}"
          issue2.save!
          issue.description = "####{issue2.id}"
          issue.save!
        end

        subject { textilizable issue, :description }

        it "doesn't replace description links with a cycle" do
          expect(subject).to match("###{issue.id}")
        end
      end

      context "Description links" do
        subject { textilizable issue, :description }

        it "replaces the macro with the issue description" do
          expect(subject).to eq("<p>#{issue.description}</p>")
        end
      end
    end

    context "Project links" do
      let(:subproject) { FactoryGirl.create :valid_project, :parent => project }
      let(:project_url) { {:controller => 'projects', :action => 'show', :id => subproject.identifier} }

      context "Plain project link" do
        subject { textilizable("project##{subproject.id}") }

        it { should eq("<p>#{link_to(subproject.name, project_url, :class => 'project')}</p>") }
      end

      context "Plain project link via identifier" do
        subject { textilizable("project:#{subproject.identifier}") }

        it { should eq("<p>#{link_to(subproject.name, project_url, :class => 'project')}</p>") }
      end

      context "Plain project link via name" do
        subject { textilizable("project:\"#{subproject.name}\"") }

        it { should eq("<p>#{link_to(subproject.name, project_url, :class => 'project')}</p>") }
      end
    end

    context "Url links" do
      subject { textilizable("http://foo.bar/FAQ#3") }

      it { should eq('<p><a class="external" href="http://foo.bar/FAQ#3">http://foo.bar/FAQ#3</a></p>') }
    end

    context "Wiki links" do
      let(:project_2) { FactoryGirl.create :valid_project,
                                           :identifier => 'onlinestore' }
      let(:wiki_1) { FactoryGirl.create :wiki,
                                        :start_page => "CookBook documentation",
                                        :project => project }
      let(:wiki_page_1_1) { FactoryGirl.create :wiki_page_with_content,
                                               :wiki => wiki_1,
                                               :title => "CookBook_documentation" }
      let(:wiki_page_1_2) { FactoryGirl.create :wiki_page_with_content,
                                               :wiki => wiki_1,
                                               :title => "Another page" }

      before do
        project_2.reload

        wiki_page_2_1 = FactoryGirl.create :wiki_page_with_content,
                                           :wiki => project_2.wiki,
                                           :title => "Start_page"

        project_2.wiki.pages << wiki_page_2_1
        project_2.wiki.start_page = "Start Page"
        project_2.wiki.save!

        project.wiki = wiki_1

        wiki_1.pages << wiki_page_1_1
        wiki_1.pages << wiki_page_1_2
      end

      context "Plain wiki link" do
        subject { textilizable('[[CookBook documentation]]') }

        it { should eq("<p><a href=\"/projects/#{project.identifier}/wiki/CookBook_documentation\" class=\"wiki-page\">CookBook documentation</a></p>") }
      end

      context "Plain wiki page link" do
        subject { textilizable('[[Another page|Page]]') }

        it { should eq("<p><a href=\"/projects/#{project.identifier}/wiki/Another_page\" class=\"wiki-page\">Page</a></p>") }
      end

      context "Wiki link with anchor" do
        subject { textilizable('[[CookBook documentation#One-section]]') }

        it { should eq("<p><a href=\"/projects/#{project.identifier}/wiki/CookBook_documentation#One-section\" class=\"wiki-page\">CookBook documentation</a></p>") }
      end

      context "Wiki page link with anchor" do
        subject { textilizable('[[Another page#anchor|Page]]') }

        it { should eq("<p><a href=\"/projects/#{project.identifier}/wiki/Another_page#anchor\" class=\"wiki-page\">Page</a></p>") }
      end

      context "Wiki link to an unknown page" do
        subject { textilizable('[[Unknown page]]') }

        it { should eq("<p><a href=\"/projects/#{project.identifier}/wiki/Unknown_page\" class=\"wiki-page new\">Unknown page</a></p>") }
      end

      context "Wiki page link to an unknown page" do
        subject { textilizable('[[Unknown page|404]]') }

        it { should eq("<p><a href=\"/projects/#{project.identifier}/wiki/Unknown_page\" class=\"wiki-page new\">404</a></p>") }
      end

      context "Link to another project's wiki" do
        subject { textilizable('[[onlinestore:]]') }

        it { should eq("<p><a href=\"/projects/onlinestore/wiki\" class=\"wiki-page\">onlinestore</a></p>") }
      end

      context "Link to another project's wiki with label" do
        subject { textilizable('[[onlinestore:|Wiki]]') }

        it { should eq("<p><a href=\"/projects/onlinestore/wiki\" class=\"wiki-page\">Wiki</a></p>") }
      end

      context "Link to another project's wiki page" do
        subject { textilizable('[[onlinestore:Start page]]') }

        it { should eq("<p><a href=\"/projects/onlinestore/wiki/Start_page\" class=\"wiki-page\">Start page</a></p>") }
      end

      context "Link to another project's wiki page with label" do
        subject { textilizable('[[onlinestore:Start page|Text]]') }

        it { should eq("<p><a href=\"/projects/onlinestore/wiki/Start_page\" class=\"wiki-page\">Text</a></p>") }
      end

      context "Link to an unknown wiki page in another project" do
        subject { textilizable('[[onlinestore:Unknown page]]') }

        it { should eq("<p><a href=\"/projects/onlinestore/wiki/Unknown_page\" class=\"wiki-page new\">Unknown page</a></p>") }
      end

      context "Striked through link to wiki page" do
        subject { textilizable('-[[Another page|Page]]-') }

        it { should eql("<p><del><a href=\"/projects/#{project.identifier}/wiki/Another_page\" class=\"wiki-page\">Page</a></del></p>") }
      end

      context "Named striked through link to wiki page" do
        subject { textilizable('-[[Another page|Page]] link-') }

        it { should eql("<p><del><a href=\"/projects/#{project.identifier}/wiki/Another_page\" class=\"wiki-page\">Page</a> link</del></p>") }
      end

      context "Escaped link to wiki page" do
        subject { textilizable('![[Another page|Page]]') }

        it { should eql('<p>[[Another page|Page]]</p>') }
      end

      context "Link to wiki of non-existing project" do
        subject { textilizable('[[unknowproject:Start]]') }

        it { should eql('<p>[[unknowproject:Start]]</p>') }
      end

      context "Link to wiki page of non-existing project" do
        subject { textilizable('[[unknowproject:Start|Page title]]') }

        it { should eql('<p>[[unknowproject:Start|Page title]]</p>') }
      end
    end

    context "Redmine links" do
      let(:repository) { FactoryGirl.create :repository, :project => project }
      let(:source_url) { {:controller => 'repositories', :action => 'entry', :project_id => identifier, :path => 'some/file'} }
      let(:source_url_with_ext) { {:controller => 'repositories', :action => 'entry', :project_id => identifier, :path => 'some/file.ext'} }

      before do
        project.repository = repository

        @to_test = {
          # source
          'source:/some/file'           => link_to('source:/some/file', source_url, :class => 'source'),
          'source:/some/file.'          => link_to('source:/some/file', source_url, :class => 'source') + ".",
          'source:/some/file.ext.'      => link_to('source:/some/file.ext', source_url_with_ext, :class => 'source') + ".",
          'source:/some/file. '         => link_to('source:/some/file', source_url, :class => 'source') + ".",
          'source:/some/file.ext. '     => link_to('source:/some/file.ext', source_url_with_ext, :class => 'source') + ".",
          'source:/some/file, '         => link_to('source:/some/file', source_url, :class => 'source') + ",",
          'source:/some/file@52'        => link_to('source:/some/file@52', source_url.merge(:rev => 52), :class => 'source'),
          'source:/some/file.ext@52'    => link_to('source:/some/file.ext@52', source_url_with_ext.merge(:rev => 52), :class => 'source'),
          'source:/some/file#L110'      => link_to('source:/some/file#L110', source_url.merge(:anchor => 'L110'), :class => 'source'),
          'source:/some/file.ext#L110'  => link_to('source:/some/file.ext#L110', source_url_with_ext.merge(:anchor => 'L110'), :class => 'source'),
          'source:/some/file@52#L110'   => link_to('source:/some/file@52#L110', source_url.merge(:rev => 52, :anchor => 'L110'), :class => 'source'),
          'export:/some/file'           => link_to('export:/some/file', source_url.merge(:format => 'raw'), :class => 'source download'),
          # escaping
          '!source:/some/file'          => 'source:/some/file',
          # invalid expressions
          'source:'                     => 'source:'
        }
      end

      it "" do
        @to_test.each do |text, result|
          textilizable(text).should eql("<p>#{result}</p>")
        end
      end
    end

    context "Pre content should not parse wiki and redmine links" do
      let(:wiki) { FactoryGirl.create :wiki,
                                      :start_page => "CookBook documentation",
                                      :project => project }
      let(:wiki_page) { FactoryGirl.create :wiki_page_with_content,
                                           :wiki => wiki,
                                           :title => "CookBook_documentation" }
      let(:raw) { <<-RAW
[[CookBook documentation]]

##{issue.id}

<pre>
[[CookBook documentation]]

##{issue.id}
</pre>
RAW
      }

      let(:expected) { <<-EXPECTED
<p><a href="/projects/#{project.identifier}/wiki/CookBook_documentation" class="wiki-page">CookBook documentation</a></p>
<p><a href="/work_packages/#{issue.id}" class="issue work_package status-3 priority-1 created-by-me" title="#{issue.subject} (#{issue.status})">##{issue.id}</a></p>
<pre>
[[CookBook documentation]]

##{issue.id}
</pre>
EXPECTED
      }

      before do
        project.wiki = wiki
        wiki.pages << wiki_page
      end

      subject { textilizable(raw).gsub(%r{[\r\n\t]}, '')}

      it { should eql(expected.gsub(%r{[\r\n\t]}, ''))}
    end
  end

  describe "other_formats_links" do
    context "link given" do
      before do
        @links = other_formats_links{|f| f.link_to 'Atom', :url => {:controller => :projects, :action => :index} }
      end
      it { @links.should == "<p class=\"other-formats\">Also available in:<span><a href=\"/projects.atom\" class=\"atom\" rel=\"nofollow\">Atom</a></span></p>"}
    end

    context "link given but disabled" do
      before do
        Setting.stub(:feeds_enabled?).and_return(false)
        @links = other_formats_links{|f| f.link_to 'Atom', :url => {:controller => :projects, :action => :index} }
      end
      it { @links.should be_nil}
    end

  end
end
