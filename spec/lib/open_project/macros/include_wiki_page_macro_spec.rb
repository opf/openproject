#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'OpenProject include wiki page macro' do
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers
  include OpenProject::TextFormatting

  def controller
    # no-op
  end

  let(:project) {
    FactoryBot.create :project,
                      enabled_module_names: %w[wiki]
  }
  let(:other_project) {
    FactoryBot.create :valid_project,
                      identifier: 'other-project',
                      enabled_module_names: %w[wiki]
  }
  let(:role) { FactoryBot.create(:role, permissions: [:view_wiki_pages]) }
  let(:user) {
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  }

  let(:included_page_other_project) {
    FactoryBot.create :wiki_page,
                      title: 'Include Test',
                      content: FactoryBot.build(:wiki_content, text: '# Included from other project')
  }

  let(:wiki_page) {
    FactoryBot.create :wiki_page,
                      title: 'Test',
                      content: FactoryBot.build(:wiki_content, text: '# My page')
  }

  let(:included_page) {
    FactoryBot.create :wiki_page,
                      title: 'Included',
                      content: FactoryBot.build(:wiki_content, text: '# included from same project')
  }

  before do
    login_as(user)

    project.wiki.pages << wiki_page
    project.wiki.pages << included_page
    project.wiki.save!

    other_project.wiki.pages << included_page_other_project
    other_project.wiki.save!
  end


  let(:input) { }
  subject { format_text(input, project: project) }

  before do
    login_as user
  end

  def error_html(exception_msg)
    "<p><macro class=\"macro-unavailable\" data-macro-name=\"include_wiki_page\">" \
          "Error executing the macro include_wiki_page (#{exception_msg})</macro></p>"
  end

  context 'old macro syntax no longer works' do
    let(:input) { '{{include(whatever)}}' }
    it { is_expected.to be_html_eql("<p>#{input}</p>") }
  end

  context 'when nothing passed' do
    let(:input) { '<macro class="include_wiki_page"></macro>' }
    it { is_expected.to be_html_eql(error_html('Missing or invalid macro parameter.')) }
  end

  context 'with invalid page' do
    let(:input) { '<macro class="include_wiki_page" data-page="Invalid"></macro>' }
    it { is_expected.to be_html_eql(error_html("Cannot find the wiki page 'Invalid'.")) }
  end

  context 'with valid page in same project' do
    let(:input) { '<macro class="include_wiki_page" data-page="included"></macro>' }
    it do
      is_expected.to be_html_eql('
        <p>
        <section class="macros--included-wiki-page" data-page-name="included">
          <h1>
            <a id="included-from-same-project" class="anchor" href="#included-from-same-project" aria-hidden="true">
              <span aria-hidden="true" class="octicon octicon-link"></span>
            </a>
            included from same project
          </h1>
        </section>
        </p>
       ')
    end
  end

  context 'with circular inclusion' do
    let(:included_page) {
      FactoryBot.create :wiki_page,
                        title: 'Included',
                        content: FactoryBot.build(:wiki_content,
                                                  text: '<macro class="include_wiki_page" data-page="test"></macro>')
    }
    let(:wiki_page) {
      FactoryBot.create :wiki_page,
                        title: 'Test',
                        content: FactoryBot.build(:wiki_content,
                                                  text: '<macro class="include_wiki_page" data-page="included"></macro>')
    }

    let(:input) { '<macro class="include_wiki_page" data-page="included"></macro>' }
    it 'includes two pagesuntil it results in a circular dependency' do
      is_expected.to be_html_eql('
        <p>
          <section class="macros--included-wiki-page" data-page-name="included">
            <p>
              <section class="macros--included-wiki-page" data-page-name="test">
                <p>
                  <macro class="macro-unavailable" data-macro-name="include_wiki_page">
                    Error executing the macro include_wiki_page (Circular inclusion of pages detected.)
                  </macro>
                </p>
              </section>
            </p>
          </section>
        </p>
       ')
    end
  end

  context 'with link to page in invisible project' do
    let(:input) { '<macro class="include_wiki_page" data-page="other-project:include-test"></macro>' }
    it { is_expected.to be_html_eql(error_html("Cannot find the wiki page 'other-project:include-test'.")) }
  end

  context 'with permissions in other project' do
    let(:role) { FactoryBot.create(:role, permissions: [:view_wiki_pages]) }
    let(:user) {
      FactoryBot.create(:user, member_in_projects: [project, other_project], member_through_role: role)
    }

    context 'can include other page' do
      let(:input) { '<macro class="include_wiki_page" data-page="other-project:include-test"></macro>' }
      it do
        is_expected.to be_html_eql('
        <p>
          <section class="macros--included-wiki-page" data-page-name="other-project:include-test">
          <h1>
            <a id="included-from-other-project" class="anchor" href="#included-from-other-project" aria-hidden="true">
              <span aria-hidden="true" class="octicon octicon-link"></span>
            </a>
            Included from other project
          </h1>
        </section>
        </p>
       ')
      end
    end
  end
end
