#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe OpenProject::TextFormatting do
  include OpenProject::TextFormatting
  include WorkPackagesHelper # soft-dependency
  include ActionView::Helpers::UrlHelper # soft-dependency
  include ActionView::Context
  include OpenProject::StaticRouting::UrlHelpers

  def controller
    # no-op
  end

  describe '.format_text' do
    let(:project) { FactoryGirl.create :valid_project }
    let(:identifier) { project.identifier }
    let(:project_member) do
      FactoryGirl.create :user,
                         member_in_project: project,
                         member_through_role: FactoryGirl.create(:role,
                                                                 permissions: [:view_work_packages, :edit_work_packages,
                                                                               :browse_repository, :view_changesets, :view_wiki_pages])
    end
    let(:issue) do
      FactoryGirl.create :work_package,
                         project: project,
                         author: project_member,
                         type: project.types.first
    end

    before do
      @project = project

      allow(User).to receive(:current).and_return(project_member)
      FactoryGirl.create(:non_member)
      allow(Setting).to receive(:text_formatting).and_return('textile')
    end

    context 'Changeset links' do
      let(:repository) do
        FactoryGirl.build_stubbed :repository_subversion,
                                  project: project
      end
      let(:changeset1) do
        FactoryGirl.build_stubbed :changeset,
                                  repository: repository,
                                  comments: 'My very first commit'
      end
      let(:changeset2) do
        FactoryGirl.build_stubbed :changeset,
                                  repository: repository,
                                  comments: 'This commit fixes #1, #2 and references #1 & #3'
      end
      let(:changeset_link) do
        link_to("r#{changeset1.revision}",
                { controller: 'repositories', action: 'revision', project_id: identifier, rev: changeset1.revision },
                class: 'changeset', title: 'My very first commit')
      end
      let(:changeset_link2) do
        link_to("r#{changeset2.revision}",
                { controller: 'repositories', action: 'revision', project_id: identifier, rev: changeset2.revision },
                class: 'changeset', title: 'This commit fixes #1, #2 and references #1 & #3')
      end

      before do
        allow(project).to receive(:repository).and_return(repository)

        changesets = [changeset1, changeset2]

        allow(Changeset).to receive(:visible).and_return(changesets)

        changesets.each do |changeset|
          allow(changesets)
            .to receive(:find_by)
            .with(repository_id: project.repository.id, revision: changeset.revision)
            .and_return(changeset)
        end
      end

      context 'Single link' do
        subject { format_text("r#{changeset1.revision}") }

        it { is_expected.to be_html_eql("<p>#{changeset_link}</p>") }
      end

      context 'Single link with dot' do
        subject { format_text("r#{changeset1.revision}.") }

        it { is_expected.to be_html_eql("<p>#{changeset_link}.</p>") }
      end

      context 'Two links comma separated' do
        subject { format_text("r#{changeset1.revision}, r#{changeset2.revision}") }

        it { is_expected.to be_html_eql("<p>#{changeset_link}, #{changeset_link2}</p>") }
      end

      context 'Single link comma separated without a space' do
        subject { format_text("r#{changeset1.revision},r#{changeset2.revision}") }

        it { is_expected.to be_html_eql("<p>#{changeset_link},#{changeset_link2}</p>") }
      end

      context 'Escaping' do
        subject { format_text("!r#{changeset1.id}") }

        it { is_expected.to be_html_eql("<p>r#{changeset1.id}</p>") }
      end
    end

    context 'Version link' do
      let!(:version) {
        FactoryGirl.create :version,
                           name: '1.0',
                           project: project
      }
      let(:version_link) {
        link_to('1.0',
                { controller: 'versions', action: 'show', id: version.id },
                class: 'version')
      }

      context 'Link with version id' do
        subject { format_text("version##{version.id}") }

        it { is_expected.to be_html_eql("<p>#{version_link}</p>") }
      end

      context 'Link with version' do
        subject { format_text('version:1.0') }
        it { is_expected.to be_html_eql("<p>#{version_link}</p>") }
      end

      context 'Link with quoted version' do
        subject { format_text('version:"1.0"') }

        it { is_expected.to be_html_eql("<p>#{version_link}</p>") }
      end

      context 'Escaping link with version id' do
        subject { format_text("!version##{version.id}") }

        it { is_expected.to be_html_eql("<p>version##{version.id}</p>") }
      end

      context 'Escaping link with version' do
        subject { format_text('!version:1.0') }

        it { is_expected.to be_html_eql('<p>version:1.0</p>') }
      end

      context 'Escaping link with quoted version' do
        subject { format_text('!version:"1.0"') }

        it { is_expected.to be_html_eql('<p>version:"1.0"</p>') }
      end
    end

    context 'Message links' do
      let(:board) { FactoryGirl.create :board, project: project }
      let(:message1) { FactoryGirl.create :message, board: board }
      let(:message2) {
        FactoryGirl.create :message,
                           board: board,
                           parent: message1
      }

      before do
        message1.reload
      end

      context 'Plain message' do
        subject { format_text("message##{message1.id}") }

        it { is_expected.to be_html_eql("<p>#{link_to(message1.subject, topic_path(message1), class: 'message')}</p>") }
      end

      context 'Message with parent' do
        subject { format_text("message##{message2.id}") }

        it { is_expected.to be_html_eql("<p>#{link_to(message2.subject, topic_path(message1, anchor: "message-#{message2.id}", r: message2.id), class: 'message')}</p>") }
      end
    end

    context 'Issue links' do
      let(:issue_link) {
        link_to("##{issue.id}",
                work_package_path(issue),
                class: 'issue work_package status-3 priority-1 created-by-me', title: "#{issue.subject} (#{issue.status})")
      }

      context 'Plain issue link' do
        subject { format_text("##{issue.id}, [##{issue.id}], (##{issue.id}) and ##{issue.id}.") }

        it { is_expected.to be_html_eql("<p>#{issue_link}, [#{issue_link}], (#{issue_link}) and #{issue_link}.</p>") }
      end

      context 'Plain issue link to non-existing element' do
        subject { format_text('#0123456789') }

        it { is_expected.to be_html_eql('<p>#0123456789</p>') }
      end

      context 'Escaping issue link' do
        subject { format_text("!##{issue.id}.") }

        it { is_expected.to be_html_eql("<p>##{issue.id}.</p>") }
      end

      context 'Cyclic Description Links' do
        let(:issue2) {
          FactoryGirl.create :work_package,
                             project: project,
                             author: project_member,
                             type: project.types.first
        }

        before do
          issue2.description = "####{issue.id}"
          issue2.save!
          issue.description = "####{issue2.id}"
          issue.save!
        end

        subject { format_text issue, :description }

        it "doesn't replace description links with a cycle" do
          expect(subject).to match("###{issue.id}")
        end
      end

      context 'Description links' do
        subject { format_text issue, :description }

        it 'replaces the macro with the issue description' do
          expect(subject).to be_html_eql("<p>#{issue.description}</p>")
        end
      end
    end

    context 'Project links' do
      let(:subproject) { FactoryGirl.create :valid_project, parent: project, is_public: true }
      let(:project_url) { { controller: 'projects', action: 'show', id: subproject.identifier } }

      context 'Plain project link' do
        subject { format_text("project##{subproject.id}") }

        it { is_expected.to be_html_eql("<p>#{link_to(subproject.name, project_url, class: 'project')}</p>") }
      end

      context 'Plain project link via identifier' do
        subject { format_text("project:#{subproject.identifier}") }

        it { is_expected.to be_html_eql("<p>#{link_to(subproject.name, project_url, class: 'project')}</p>") }
      end

      context 'Plain project link via name' do
        subject { format_text("project:\"#{subproject.name}\"") }

        it { is_expected.to be_html_eql("<p>#{link_to(subproject.name, project_url, class: 'project')}</p>") }
      end
    end

    context 'User links' do
      let(:role) do
        FactoryGirl.create :role,
                           permissions: [:view_work_packages, :edit_work_packages,
                                         :browse_repository, :view_changesets, :view_wiki_pages]
      end

      let(:linked_project_member) do
        FactoryGirl.create :user,
                           member_in_project: project,
                           member_through_role: role
      end

      context 'User link via ID' do
        context 'when linked user visible for reader' do
          subject { format_text("user##{linked_project_member.id}") }

          it {
            is_expected.to be_html_eql("<p>#{link_to(linked_project_member.name, { controller: :users, action: :show, id: linked_project_member.id }, class: 'user-mention')}</p>")
          }
        end

        context 'when linked user not visible for reader' do
          let(:role) { FactoryGirl.create(:non_member) }

          subject { format_text("user##{linked_project_member.id}") }

          it {
            is_expected.to be_html_eql("<p>user##{linked_project_member.id}</p>")
          }
        end

      end

      context 'User link via login name' do
        context 'when linked user visible for reader' do
          context 'with a common login name' do
            subject { format_text("user:\"#{linked_project_member.login}\"") }

            it { is_expected.to be_html_eql("<p>#{link_to(linked_project_member.name, { controller: :users, action: :show, id: linked_project_member.id }, class: 'user-mention')}</p>") }
          end

          context "with an email address as login name" do
            let(:linked_project_member) do
              FactoryGirl.create :user,
                                 member_in_project: project,
                                 member_through_role: role,
                                 login: "foo@bar.com"
            end
            subject { format_text("user:\"#{linked_project_member.login}\"") }

            it { is_expected.to be_html_eql("<p>#{link_to(linked_project_member.name, { controller: :users, action: :show, id: linked_project_member.id }, class: 'user-mention')}</p>") }
          end
        end

        context 'when linked user not visible for reader' do
          let(:role) { FactoryGirl.create(:non_member) }

          subject { format_text("user:\"#{linked_project_member.login}\"") }

          it {
            is_expected.to be_html_eql("<p>user:\"#{linked_project_member.login}\"</p>")
          }
        end
      end
    end

    context 'Url links' do
      subject { format_text('http://foo.bar/FAQ#3') }

      it { is_expected.to be_html_eql('<p><a class="external icon-context icon-copy" href="http://foo.bar/FAQ#3">http://foo.bar/FAQ#3</a></p>') }
    end

    context 'Wiki links' do
      let(:project_2) {
        FactoryGirl.create :valid_project,
                           identifier: 'onlinestore'
      }
      let(:wiki_1) {
        FactoryGirl.create :wiki,
                           start_page: 'CookBook documentation',
                           project: project
      }
      let(:wiki_page_1_1) {
        FactoryGirl.create :wiki_page_with_content,
                           wiki: wiki_1,
                           title: 'CookBook documentation'
      }
      let(:wiki_page_1_2) {
        FactoryGirl.create :wiki_page_with_content,
                           wiki: wiki_1,
                           title: 'Another page'
      }
      let(:wiki_page_1_3) {
        FactoryGirl.create :wiki_page_with_content,
                           wiki: wiki_1,
                           title: '<script>alert("FOO")</script>'
      }

      before do
        project_2.reload

        wiki_page_2_1 = FactoryGirl.create :wiki_page_with_content,
                                           wiki: project_2.wiki,
                                           title: 'Start Page'

        project_2.wiki.pages << wiki_page_2_1
        project_2.wiki.start_page = 'Start Page'
        project_2.wiki.save!

        project.wiki = wiki_1

        wiki_1.pages << wiki_page_1_1
        wiki_1.pages << wiki_page_1_2
        wiki_1.pages << wiki_page_1_3
      end

      context 'Plain wiki link' do
        subject { format_text('[[CookBook documentation]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/#{project.identifier}/wiki/cookbook-documentation\">CookBook documentation</a></p>") }
      end

      context 'Arbitrary wiki link' do
        title = '<script>alert("FOO")</script>'
        subject { format_text("[[#{title}]]") }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/#{project.identifier}/wiki/alert-foo\">#{h(title)}</a></p>") }
      end

      context 'Plain wiki page link' do
        subject { format_text('[[Another page|Page]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/#{project.identifier}/wiki/another-page\">Page</a></p>") }
      end

      context 'Wiki link with anchor' do
        subject { format_text('[[CookBook documentation#One-section]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/#{project.identifier}/wiki/cookbook-documentation#One-section\">CookBook documentation</a></p>") }
      end

      context 'Wiki page link with anchor' do
        subject { format_text('[[Another page#anchor|Page]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/#{project.identifier}/wiki/another-page#anchor\">Page</a></p>") }
      end

      context 'Wiki link to an unknown page' do
        subject { format_text('[[Unknown page]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page new\" href=\"/projects/#{project.identifier}/wiki/unknown-page\">Unknown page</a></p>") }
      end

      context 'Wiki page link to an unknown page' do
        subject { format_text('[[Unknown page|404]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page new\" href=\"/projects/#{project.identifier}/wiki/unknown-page\">404</a></p>") }
      end

      context "Link to another project's wiki" do
        subject { format_text('[[onlinestore:]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/onlinestore/wiki/start-page\">onlinestore</a></p>") }
      end

      context "Link to another project's wiki with label" do
        subject { format_text('[[onlinestore:|Wiki]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/onlinestore/wiki/start-page\">Wiki</a></p>") }
      end

      context "Link to another project's wiki page" do
        subject { format_text('[[onlinestore:Start page]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/onlinestore/wiki/start-page\">Start Page</a></p>") }
      end

      context "Link to another project's wiki page with label" do
        subject { format_text('[[onlinestore:Start page|Text]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page\" href=\"/projects/onlinestore/wiki/start-page\">Text</a></p>") }
      end

      context 'Link to an unknown wiki page in another project' do
        subject { format_text('[[onlinestore:Unknown page]]') }

        it { is_expected.to be_html_eql("<p><a class=\"wiki-page new\" href=\"/projects/onlinestore/wiki/unknown-page\">Unknown page</a></p>") }
      end

      context 'Struck through link to wiki page' do
        subject { format_text('-[[Another page|Page]]-') }

        it { is_expected.to be_html_eql("<p><del><a class=\"wiki-page\" href=\"/projects/#{project.identifier}/wiki/another-page\">Page</a></del></p>") }
      end

      context 'Named struck through link to wiki page' do
        subject { format_text('-[[Another page|Page]] link-') }

        it { is_expected.to be_html_eql("<p><del><a class=\"wiki-page\" href=\"/projects/#{project.identifier}/wiki/another-page\">Page</a> link</del></p>") }
      end

      context 'Escaped link to wiki page' do
        subject { format_text('![[Another page|Page]]') }

        it { is_expected.to be_html_eql('<p>[[Another page|Page]]</p>') }
      end

      context 'Link to wiki of non-existing project' do
        subject { format_text('[[unknowproject:Start]]') }

        it { is_expected.to be_html_eql('<p>[[unknowproject:Start]]</p>') }
      end

      context 'Link to wiki page of non-existing project' do
        subject { format_text('[[unknowproject:Start|Page title]]') }

        it { is_expected.to be_html_eql('<p>[[unknowproject:Start|Page title]]</p>') }
      end
    end

    context 'Redmine links' do
      let(:repository) do
        FactoryGirl.build_stubbed :repository_subversion, project: project
      end
      let(:source_url) do
        { controller: 'repositories',
          action: 'entry',
          project_id: identifier,
          path: 'some/file' }
      end
      let(:source_url_with_ext) do
        { controller: 'repositories',
          action: 'entry',
          project_id: identifier,
          path: 'some/file.ext' }
      end

      before do
        allow(project).to receive(:repository).and_return(repository)
        allow(User).to receive(:current).and_return(project_member)
        allow(project_member)
          .to receive(:allowed_to?)
          .with(:browse_repository, project)
          .and_return(true)

        @to_test = {
          # source
          'source:/some/file'           => link_to('source:/some/file', source_url, class: 'source'),
          'source:/some/file.'          => link_to('source:/some/file', source_url, class: 'source') + '.',
          'source:/some/file.ext.'      => link_to('source:/some/file.ext', source_url_with_ext, class: 'source') + '.',
          'source:/some/file. '         => link_to('source:/some/file', source_url, class: 'source') + '.',
          'source:/some/file.ext. '     => link_to('source:/some/file.ext', source_url_with_ext, class: 'source') + '.',
          'source:/some/file, '         => link_to('source:/some/file', source_url, class: 'source') + ',',
          'source:/some/file@52'        => link_to('source:/some/file@52', source_url.merge(rev: 52), class: 'source'),
          'source:/some/file.ext@52'    => link_to('source:/some/file.ext@52', source_url_with_ext.merge(rev: 52), class: 'source'),
          'source:/some/file#L110'      => link_to('source:/some/file#L110', source_url.merge(anchor: 'L110'), class: 'source'),
          'source:/some/file.ext#L110'  => link_to('source:/some/file.ext#L110', source_url_with_ext.merge(anchor: 'L110'), class: 'source'),
          'source:/some/file@52#L110'   => link_to('source:/some/file@52#L110', source_url.merge(rev: 52, anchor: 'L110'), class: 'source'),
          'export:/some/file'           => link_to('export:/some/file', source_url.merge(format: 'raw'), class: 'source download'),
          # escaping
          '!source:/some/file'          => 'source:/some/file',
          # invalid expressions
          'source:'                     => 'source:'
        }
      end

      it '' do
        @to_test.each do |text, result|
          expect(format_text(text)).to be_html_eql("<p>#{result}</p>")
        end
      end
    end

    context 'Pre content should not parse wiki and redmine links' do
      let(:wiki) {
        FactoryGirl.create :wiki,
                           start_page: 'CookBook documentation',
                           project: project
      }
      let(:wiki_page) {
        FactoryGirl.create :wiki_page_with_content,
                           wiki: wiki,
                           title: 'CookBook documentation'
      }
      let(:raw) {
        <<-RAW
[[CookBook documentation]]

##{issue.id}

<pre>
[[CookBook documentation]]

##{issue.id}
</pre>
RAW
      }

      let(:expected) {
        <<-EXPECTED
<p><a class="wiki-page" href="/projects/#{project.identifier}/wiki/cookbook-documentation">CookBook documentation</a></p>
<p><a class="issue work_package status-3 priority-1 created-by-me" href="/work_packages/#{issue.id}" title="#{issue.subject} (#{issue.status})">##{issue.id}</a></p>
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

      subject { format_text(raw) }

      it { is_expected.to be_html_eql(expected) }
    end

    describe 'options' do
      describe '#format' do
        it 'uses format of Settings, if nothing is specified' do
          expect(format_text('*Stars!*')).to be_html_eql('<p><strong>Stars!</strong></p>')
        end

        it 'uses format of options, if specified' do
          expect(format_text('*Stars!*', format: 'plain')).to be_html_eql('<p>*Stars!*</p>')
        end
      end
    end
  end

  describe 'macros within pre block' do
    let(:wiki_text) {
      <<-WIKI_TEXT
      <pre>{{include(wiki)}}</pre>

      {{include(wiki)}}
      WIKI_TEXT
    }

    subject(:html) { format_text(wiki_text) }

    it 'does not expand the macro within <pre>'  do
      expect(html).to be_html_eql(%[
        <pre>{{ $root.DOUBLE_LEFT_CURLY_BRACE }}include(wiki)}}</pre>
        <p>
          <span class=\"flash error macro-unavailable permanent\"> Error executing the macro include (Page not found) </span>
        </p>
      ])
    end
  end

  describe '{{toc}}', 'table of contents macro' do
    # Source: http://en.wikipedia.org/wiki/Orange_(fruit)
    let(:wiki_text) {
      <<-WIKI_TEXT
{{toc}}

h1. Orange

h2. Varietes

h3. Common Oranges

h4. Valencia

h5. Naranjito

h4. Hart's Tardiff Valencia

h3. Navel Oranges

h3. Blood Oranges

h3. Acidless Oranges

h2. Attributes

WIKI_TEXT
    }

    subject(:html) { format_text(wiki_text) }

    context 'w/o request present' do
      let(:request) { nil }

      it 'emits a table of contents for headings h1-h4 with anchors' do
        expect(html).to be_html_eql(%{
          <fieldset class='form--fieldset -collapsible'>
            <legend class='form--fieldset-legend' title='Show/Hide table of contents' onclick='toggleFieldset(this);'>
              <a href='javascript:'>Table of Contents</a>
            </legend>
            <div>
              <ul class="toc">
                <li>
                  <a href="#Orange">Orange</a>
                  <ul>
                    <li>
                      <a href="#Varietes">Varietes</a>
                      <ul>
                        <li>
                          <a href="#Common-Oranges">Common Oranges</a>
                          <ul>
                            <li><a href="#Valencia">Valencia</a></li>
                            <li><a href="#Harts-Tardiff-Valencia">Hart's Tardiff Valencia</a></li>
                          </ul>
                        </li>
                        <li><a href="#Navel-Oranges">Navel Oranges</a></li>
                        <li><a href="#Blood-Oranges">Blood Oranges</a></li>
                        <li><a href="#Acidless-Oranges">Acidless Oranges</a></li>
                      </ul>
                    </li>
                    <li><a href="#Attributes">Attributes</a></li>
                  </ul>
                </li>
              </ul>
            </div>
          </fieldset>
        }).at_path('fieldset')
      end
    end
  end

  context 'deprecated methods' do
    subject { self }

    it { is_expected.to respond_to :textilizable }
    it { is_expected.to respond_to :textilize    }
  end
end
