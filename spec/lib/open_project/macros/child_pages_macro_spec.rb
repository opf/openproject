#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

describe 'OpenProject child pages macro' do
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers
  include OpenProject::TextFormatting

  def controller
    # no-op
  end

  let(:project) {
    FactoryBot.create :valid_project,
                      enabled_module_names: %w[wiki]
  }
  let(:member_project) {
    FactoryBot.create :valid_project,
                      identifier: 'member-project',
                      enabled_module_names: %w[wiki]
  }
  let(:invisible_project) {
    FactoryBot.create :valid_project,
                      identifier: 'other-project',
                      enabled_module_names: %w[wiki]
  }
  let(:role) { FactoryBot.create(:role, permissions: [:view_wiki_pages]) }
  let(:user) {
    FactoryBot.create(:user, member_in_projects: [project, member_project], member_through_role: role)
  }

  let(:current_page) {
    FactoryBot.create :wiki_page,
                      title: 'Current page',
                      wiki: project.wiki,
                      content: FactoryBot.build(:wiki_content, text: input)
  }

  let(:middle_page) {
    FactoryBot.create :wiki_page,
                      title: 'Node from same project',
                      wiki: project.wiki,
                      parent_id: current_page.id,
                      content: FactoryBot.build(:wiki_content, text: '# Node Page from same project')
  }

  let(:node_page_invisible_project) {
    FactoryBot.create :wiki_page,
                      title: 'Node page from invisible project',
                      wiki: invisible_project.wiki,
                      content: FactoryBot.build(:wiki_content, text: '# Page from invisible project')
  }

  let(:leaf_page) {
    FactoryBot.create :wiki_page,
                      title: 'Leaf page from same project',
                      parent_id: middle_page.id,
                      wiki: project.wiki,
                      content: FactoryBot.build(:wiki_content, text: '# Leaf page from same project')
  }

  let(:leaf_page_invisible_project) {
    FactoryBot.create :wiki_page,
                      title: 'Leaf page from invisible project',
                      parent_id: node_page_invisible_project.id,
                      wiki: invisible_project.wiki,
                      content: FactoryBot.build(:wiki_content, text: '# Leaf page from invisible project')
  }

  let(:leaf_page_member_project) {
    FactoryBot.create :wiki_page,
                      title: 'Leaf page from member project',
                      wiki: member_project.wiki,
                      content: FactoryBot.build(:wiki_content, text: '# Leaf page from member project')
  }

  before do
    login_as(user)
  end

  let(:input) { }
  subject { format_text(current_page.content, :text) }

  before do
    login_as user
    leaf_page
    leaf_page_invisible_project
    allow(Setting).to receive(:text_formatting).and_return('markdown')
  end

  def error_html(exception_msg)
    "<p><macro class=\"macro-unavailable\" data-macro-name=\"child_pages\">" \
          "Error executing the macro child_pages (#{exception_msg})</macro></p>"
  end

  context 'with invalid page' do
    let(:input) { '<macro class="child_pages" data-page="Invalid"></macro>' }
    it { is_expected.to be_html_eql(error_html("Cannot find the wiki page 'Invalid'.")) }
  end

  context 'old macro syntax no longer works' do
    let(:input) { '{{child_pages(whatever)}}' }
    it { is_expected.to be_html_eql("<p>#{input}</p>") }
  end

  context 'when nothing passed' do
    let(:input) { '<macro class="child_pages"></macro>' }
    it { is_expected.not_to match(current_page.title) }
    it { is_expected.to match(middle_page.title) }
    it { is_expected.to match(leaf_page.title) }
    # Check accessability
    it { is_expected.to include('hidden-for-sighted', 'tabindex', 'Expanded. Click to collapse') }
  end

  context 'when only include_parent passed' do
    let(:input) { '<macro class="child_pages" data-include-parent="true"></macro>' }
    it { is_expected.to match(current_page.title) }
    it { is_expected.to match(middle_page.title) }
    it { is_expected.to match(leaf_page.title) }
  end

  context 'when page title from same project passed' do
    let(:input) { '<macro class="child_pages" data-page="Node from same project"></macro>' }
    it { is_expected.not_to match(current_page.title) }
    it { is_expected.not_to match(middle_page.title) }
    it { is_expected.to match(leaf_page.title) }
  end

  context 'when page slug from same project passed' do
    let(:input) { '<macro class="child_pages" data-page="node-from-same-project"></macro>' }
    it { is_expected.not_to match(current_page.title) }
    it { is_expected.not_to match(middle_page.title) }
    it { is_expected.to match(leaf_page.title) }
  end

  context 'when page title from same project with include_parent passed' do
    let(:input) { '<macro class="child_pages" data-page="Node from same project" data-include-parent="true"></macro>' }
    it { is_expected.to_not match(current_page.title) }
    it { is_expected.to match(middle_page.title) }
    it { is_expected.to match(leaf_page.title) }
  end

  context 'when page slug from invisible project passed' do
    let(:input) { '<macro class="child_pages" data-page="other-project:leaf-page-from-other-project"></macro>' }
    it { is_expected.to be_html_eql(error_html("Cannot find the wiki page 'other-project:leaf-page-from-other-project'.")) }
  end

  context 'when referencing page from a member project' do
    let(:input) { '<macro class="child_pages" data-page="member-project:leaf-page-from-member-project" data-include-parent="true"></macro>' }
    before { leaf_page_member_project }
    it { is_expected.to match(leaf_page_member_project.title) }
  end
end
