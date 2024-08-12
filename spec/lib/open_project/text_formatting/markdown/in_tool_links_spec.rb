#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting,
               "in tool links" do
  include_context "expected markdown modules"

  describe ".format_text" do
    shared_let(:project) { create(:valid_project) }
    let(:identifier) { project.identifier }

    shared_let(:role) do
      create(:project_role,
             permissions: %i(view_work_packages edit_work_packages
                             browse_repository view_changesets view_wiki_pages))
    end

    shared_let(:project_member) do
      create(:user,
             member_with_roles: { project => role })
    end
    shared_let(:work_package) do
      create(:work_package,
             project:,
             author: project_member,
             type: project.types.first)
    end

    shared_let(:non_member) do
      create(:non_member)
    end

    before do
      @project = project
      allow(User).to receive(:current).and_return(project_member)
    end

    context "Changeset links" do
      let(:repository) do
        build_stubbed(:repository_subversion,
                      project:)
      end
      let(:changeset1) do
        build_stubbed(:changeset,
                      repository:,
                      comments: "My very first commit")
      end
      let(:changeset2) do
        build_stubbed(:changeset,
                      repository:,
                      comments: "This commit fixes #1, #2 and references #1 & #3")
      end
      let(:changeset_link) do
        link_to("r#{changeset1.revision}",
                { controller: "repositories", action: "revision", project_id: identifier, rev: changeset1.revision },
                class: "changeset op-uc-link", title: "My very first commit", target: "_top")
      end
      let(:changeset_link2) do
        link_to("r#{changeset2.revision}",
                { controller: "repositories", action: "revision", project_id: identifier, rev: changeset2.revision },
                class: "changeset op-uc-link", title: "This commit fixes #1, #2 and references #1 & #3", target: "_top")
      end

      before do
        allow(project).to receive(:repository).and_return(repository)

        allow(repository).to receive(:find_changeset_by_name).with(changeset1.revision).and_return(changeset1)
        allow(repository).to receive(:find_changeset_by_name).with(changeset2.revision).and_return(changeset2)
      end

      context "Single link" do
        subject { format_text("r#{changeset1.revision}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{changeset_link}</p>") }
      end

      context "Single link with dot" do
        subject { format_text("r#{changeset1.revision}. A word") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{changeset_link}. A word</p>") }
      end

      context "Two links comma separated" do
        subject { format_text("r#{changeset1.revision}, r#{changeset2.revision}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{changeset_link}, #{changeset_link2}</p>") }
      end

      context "Single link comma separated without a space" do
        subject { format_text("r#{changeset1.revision},r#{changeset2.revision}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{changeset_link},#{changeset_link2}</p>") }
      end

      context "Escaping" do
        subject { format_text("!r#{changeset1.id}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>r#{changeset1.id}</p>") }
      end
    end

    context "Version link" do
      let!(:version) do
        create(:version,
               name: "1.0",
               project:)
      end
      let(:version_link) do
        link_to("1.0",
                { controller: "versions", action: "show", id: version.id },
                class: "version op-uc-link", target: "_top")
      end

      context "Link with version id" do
        subject { format_text("version##{version.id}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{version_link}</p>") }
      end

      context "Link with version" do
        subject { format_text("version:1.0") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{version_link}</p>") }
      end

      context "Link with quoted version" do
        subject { format_text('version:"1.0"') }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{version_link}</p>") }
      end

      context "Escaping link with version id" do
        subject { format_text("!version##{version.id}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>version##{version.id}</p>") }
      end

      context "Escaping link with version" do
        subject { format_text("!version:1.0") }

        it { is_expected.to be_html_eql('<p class="op-uc-p">version:1.0</p>') }
      end

      context "Escaping link with quoted version" do
        subject { format_text('!version:"1.0"') }

        it { is_expected.to be_html_eql('<p class="op-uc-p">version:"1.0"</p>') }
      end
    end

    context "Query link" do
      let!(:query) do
        create(:query,
               name: "project plan with milestones",
               project:)
      end
      let(:query_link) do
        link_to(
          "project plan with milestones",
          project_work_packages_path([query.project.id], query_id: query.id),
          class: "query op-uc-link",
          target: "_top"
        )
      end

      context "Link with query id" do
        subject { format_text("view##{query.id}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{query_link}</p>") }
      end

      context "Escaping link with view id" do
        subject { format_text("!view##{query.id}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>view##{query.id}</p>") }
      end
    end

    context "Default work package query link" do
      let(:default_query_link) do
        link_to(
          "Work packages",
          project_work_packages_path([project.id]),
          class: "query op-uc-link",
          target: "_top"
        )
      end

      context "Link to default work package query" do
        subject { format_text("view:default") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{default_query_link}</p>") }
      end

      context "Escaping link to default work package query" do
        subject { format_text("!view:default") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>view:default</p>") }
      end
    end

    context "Message links" do
      let(:forum) { create(:forum, project:) }
      let(:message1) { create(:message, forum:) }
      let(:message2) do
        create(:message,
               forum:,
               parent: message1)
      end

      before do
        message1.reload
      end

      context "Plain message" do
        subject { format_text("message##{message1.id}") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'>#{link_to(message1.subject, topic_path(message1),
                                                                       class: 'message op-uc-link',
                                                                       target: '_top')}</p>")
        }
      end

      context "Message with parent" do
        subject { format_text("message##{message2.id}") }

        it {
          link = link_to(message2.subject,
                         topic_path(message1, anchor: "message-#{message2.id}", r: message2.id),
                         class: "message op-uc-link",
                         target: "_top")
          expect(subject).to be_html_eql("<p class='op-uc-p'>#{link}</p>")
        }
      end
    end

    context "Work package links" do
      let(:work_package_link) do
        link_to("##{work_package.id}",
                work_package_path(work_package),
                class: "issue work_package preview-trigger op-uc-link",
                target: "_top")
      end

      context "Plain work_package link" do
        subject { format_text("##{work_package.id}, [##{work_package.id}], (##{work_package.id}) and ##{work_package.id}.") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'>#{work_package_link}, [#{work_package_link}], (#{work_package_link}) and #{work_package_link}.</p>")
        }
      end

      context "Plain work_package link with braces" do
        subject { format_text("foo (bar ##{work_package.id})") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>foo (bar #{work_package_link})</p>") }
      end

      context "Plain work_package link to non-existing element still links" do
        subject { format_text("#0123456789") }

        it {
          expect(subject).to be_html_eql('<p class="op-uc-p">#0123456789</p>')
        }
      end

      describe "double hash work_package link" do
        let(:work_package_link) do
          content_tag "opce-macro-wp-quickinfo",
                      "",
                      data: { id: "1234", detailed: "false" }
        end

        subject { format_text("foo (bar ##1234)") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>foo (bar #{work_package_link})</p>") }
      end

      describe "triple hash work_package link" do
        let(:work_package_link) do
          content_tag "opce-macro-wp-quickinfo",
                      "",
                      data: { id: "1234", detailed: "true" }
        end

        subject { format_text("foo (bar ###1234)") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>foo (bar #{work_package_link})</p>") }
      end

      context "Escaping work_package link" do
        subject { format_text("Some leading text. !##{work_package.id}. Some following") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>Some leading text. ##{work_package.id}. Some following</p>") }
      end

      context "Escaping work_package link" do
        subject { format_text("!##{work_package.id}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>##{work_package.id}</p>") }
      end

      context "WP subject with escapable chars" do
        let(:work_package) do
          create(:work_package, subject: "Title with \"quote\" and 'sòme 'chárs.")
        end

        let(:work_package_link) do
          link_to("##{work_package.id}",
                  work_package_path(work_package),
                  class: "issue work_package preview-trigger op-uc-link",
                  target: "_top")
        end

        subject { format_text("##{work_package.id}") }

        it { is_expected.to be_html_eql("<p class='op-uc-p'>#{work_package_link}</p>") }
      end

      context "Description links" do
        subject { format_text work_package, :description }

        it "replaces the macro with the work_package description" do
          expect(subject).to be_html_eql("<p class='op-uc-p'>#{work_package.description}</p>")
        end
      end
    end

    context "Project links" do
      let(:subproject) { create(:valid_project, parent: project, public: true) }
      let(:project_url) { project_overview_path(subproject) }

      context "Plain project link" do
        subject { format_text("project##{subproject.id}") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'>#{link_to(subproject.name, project_url,
                                                                       target: '_top',
                                                                       class: 'project op-uc-link')}</p>")
        }
      end

      context "Plain project link via identifier" do
        subject { format_text("project:#{subproject.identifier}") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'>#{link_to(subproject.name, project_url,
                                                                       target: '_top',
                                                                       class: 'project op-uc-link')}</p>")
        }
      end

      context "Plain project link via name" do
        subject { format_text("project:\"#{subproject.name}\"") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'>#{link_to(subproject.name, project_url,
                                                                       target: '_top',
                                                                       class: 'project op-uc-link')}</p>")
        }
      end
    end

    context "Wiki links" do
      let(:project_2) do
        create(:valid_project,
               identifier: "onlinestore")
      end
      let(:wiki_1) do
        create(:wiki,
               start_page: "CookBook documentation",
               project:)
      end
      let(:wiki_page_1_1) do
        create(:wiki_page,
               wiki: wiki_1,
               title: "CookBook documentation")
      end
      let(:wiki_page_1_2) do
        create(:wiki_page,
               wiki: wiki_1,
               title: "Another page")
      end
      let(:wiki_page_1_3) do
        create(:wiki_page,
               wiki: wiki_1,
               title: '<script>alert("FOO")</script>')
      end

      before do
        project_2.reload

        wiki_page_2_1 = create(:wiki_page,
                               wiki: project_2.wiki,
                               title: "Start Page")

        project_2.wiki.pages << wiki_page_2_1
        project_2.wiki.start_page = "Start Page"
        project_2.wiki.save!

        project.wiki = wiki_1

        wiki_1.pages << wiki_page_1_1
        wiki_1.pages << wiki_page_1_2
        wiki_1.pages << wiki_page_1_3
      end

      context "Plain wiki link" do
        subject { format_text("[[CookBook documentation]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/cookbook-documentation\">CookBook documentation</a></p>")
        }
      end

      context "Arbitrary wiki link" do
        title = '<script>alert("FOO")</script>'
        subject { format_text("[[#{title}]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/alert-foo\">#{h(title)}</a></p>")
        }
      end

      context "Plain wiki page link" do
        subject { format_text("[[Another page|Page]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/another-page\">Page</a></p>")
        }
      end

      context "Wiki link with anchor" do
        subject { format_text("[[CookBook documentation#One-section]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\"  href=\"/projects/#{project.identifier}/wiki/cookbook-documentation#One-section\">CookBook documentation</a></p>")
        }
      end

      context "Wiki page link with anchor" do
        subject { format_text("[[Another page#anchor|Page]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/another-page#anchor\">Page</a></p>")
        }
      end

      context "Wiki link to an unknown page" do
        subject { format_text("[[Unknown page]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page new op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/unknown-page?title=Unknown+page\">Unknown page</a></p>")
        }
      end

      context "Wiki page link to an unknown page" do
        subject { format_text("[[Unknown page|404]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page new op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/unknown-page?title=404\">404</a></p>")
        }
      end

      context "Link to another project's wiki" do
        subject { format_text("[[onlinestore:]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/onlinestore/wiki/start-page\">onlinestore</a></p>")
        }
      end

      context "Link to another project's wiki with label" do
        subject { format_text("[[onlinestore:|Wiki]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/onlinestore/wiki/start-page\">Wiki</a></p>")
        }
      end

      context "Link to another project's wiki page" do
        subject { format_text("[[onlinestore:Start page]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/onlinestore/wiki/start-page\">Start Page</a></p>")
        }
      end

      context "Link to another project's wiki page with label" do
        subject { format_text("[[onlinestore:Start page|Text]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/onlinestore/wiki/start-page\">Text</a></p>")
        }
      end

      context "Link to an unknown wiki page in another project" do
        subject { format_text("[[onlinestore:Unknown page]]") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><a class=\"wiki-page new op-uc-link\" target=\"_top\" href=\"/projects/onlinestore/wiki/unknown-page?title=Unknown+page\">Unknown page</a></p>")
        }
      end

      context "Struck through link to wiki page" do
        subject { format_text("~~[[Another page|Page]]~~") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><del><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/another-page\">Page</a></del></p>")
        }
      end

      context "Named struck through link to wiki page" do
        subject { format_text("~~[[Another page|Page]] link~~") }

        it {
          expect(subject).to be_html_eql("<p class='op-uc-p'><del><a class=\"wiki-page op-uc-link\" target=\"_top\" href=\"/projects/#{project.identifier}/wiki/another-page\">Page</a> link</del></p>")
        }
      end

      context "Escaped link to wiki page" do
        subject { format_text("![[Another page|Page]]") }

        it { is_expected.to be_html_eql('<p class="op-uc-p">[[Another page|Page]]</p>') }
      end

      context "Link to wiki of non-existing project" do
        subject { format_text("[[unknowproject:Start]]") }

        it { is_expected.to be_html_eql('<p class="op-uc-p">[[unknowproject:Start]]</p>') }
      end

      context "Link to wiki page of non-existing project" do
        subject { format_text("[[unknowproject:Start|Page title]]") }

        it { is_expected.to be_html_eql('<p class="op-uc-p">[[unknowproject:Start|Page title]]</p>') }
      end
    end

    context "Redmine links" do
      let(:repository) do
        build_stubbed(:repository_subversion, project:)
      end

      def source_url(**)
        entry_revision_project_repository_path(project_id: identifier, repo_path: "some/file", **)
      end

      def source_url_with_ext(**)
        entry_revision_project_repository_path(project_id: identifier, repo_path: "some/file.ext", **)
      end

      before do
        allow(project).to receive(:repository).and_return(repository)
        allow(User).to receive(:current).and_return(project_member)

        mock_permissions_for(project_member) do |mock|
          mock.allow_in_project :browse_repository, project:
        end

        @to_test = {
          # source
          "source:/some/file" => link_to("source:/some/file", source_url, class: "source op-uc-link", target: "_top"),
          "source:/some/file." => link_to("source:/some/file", source_url, class: "source op-uc-link", target: "_top") + ".",
          'source:"/some/file.ext".' => link_to("source:/some/file.ext", source_url_with_ext, class: "source op-uc-link",
                                                                                              target: "_top") + ".",
          "source:/some/file. " => link_to("source:/some/file", source_url, class: "source op-uc-link", target: "_top") + ".",
          'source:"/some/file.ext". ' => link_to("source:/some/file.ext", source_url_with_ext, class: "source op-uc-link",
                                                                                               target: "_top") + ".",
          "source:/some/file, " => link_to("source:/some/file", source_url, class: "source op-uc-link", target: "_top") + ",",
          "source:/some/file@52" => link_to("source:/some/file@52", source_url(rev: 52), class: "source op-uc-link",
                                                                                         target: "_top"),
          'source:"/some/file.ext@52"' => link_to("source:/some/file.ext@52", source_url_with_ext(rev: 52),
                                                  class: "source op-uc-link",
                                                  target: "_top"),
          'source:"/some/file#L110"' => link_to("source:/some/file#L110", source_url(anchor: "L110"), class: "source op-uc-link",
                                                                                                      target: "_top"),
          'source:"/some/file.ext#L110"' => link_to("source:/some/file.ext#L110", source_url_with_ext(anchor: "L110"),
                                                    class: "source op-uc-link",
                                                    target: "_top"),
          'source:"/some/file@52#L110"' => link_to("source:/some/file@52#L110", source_url(rev: 52, anchor: "L110"),
                                                   class: "source op-uc-link",
                                                   target: "_top"),
          "export:/some/file" => link_to("export:/some/file", source_url(format: "raw"),
                                         class: "source download op-uc-link",
                                         target: "_top"),
          # escaping
          "!source:/some/file" => "source:/some/file",
          # invalid expressions
          "source:" => "source:"
        }
      end

      it "" do
        @to_test.each do |text, result|
          expect(format_text(text)).to be_html_eql("<p class='op-uc-p'>#{result}</p>")
        end
      end
    end

    context "Pre content should not parse wiki and redmine links" do
      let(:wiki) do
        create(:wiki,
               start_page: "CookBook documentation",
               project:)
      end
      let(:wiki_page) do
        create(:wiki_page,
               wiki:,
               title: "CookBook documentation")
      end
      let(:raw) do
        <<~RAW
          [[CookBook documentation]]

          ##{work_package.id}

          ```
          [[CookBook documentation]]

          ##{work_package.id}
          ```
          </pre>
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class='op-uc-p'><a class="wiki-page op-uc-link" target="_top" href="/projects/#{project.identifier}/wiki/cookbook-documentation">CookBook documentation</a></p>
          <p class='op-uc-p'><a class="issue work_package preview-trigger op-uc-link" target="_top" href="/work_packages/#{work_package.id}">##{work_package.id}</a></p>
          <pre class="op-uc-code-block">
          [[CookBook documentation]]

          ##{work_package.id}
          </pre>
        EXPECTED
      end

      before do
        project.wiki = wiki
        wiki.pages << wiki_page
      end

      subject { format_text(raw) }

      it { is_expected.to be_html_eql(expected) }
    end
  end
end
