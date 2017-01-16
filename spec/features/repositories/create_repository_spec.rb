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
require 'features/repositories/repository_settings_page'

describe 'Create repository', type: :feature, js: true, selenium: true do
  let(:current_user) { FactoryGirl.create (:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:settings_page) { RepositorySettingsPage.new(project) }

  # Allow to override configuration values to determine
  # whether to activate managed repositories
  let(:enabled_scms) { %w[subversion git] }
  let(:config) { nil }

  let(:scm_vendor_input_css) { 'select[name="scm_vendor"]' }
  let(:scm_vendor_input) { find(scm_vendor_input_css) }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)

    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)
  end

  describe 'vendor select' do
    before do
      settings_page.visit_repository_settings
    end
    shared_examples 'shows enabled scms' do
      it 'displays the vendor selection' do
        expect(scm_vendor_input).not_to be_nil
        enabled_scms.each do |scm|
          expect(scm_vendor_input).to have_selector('option', text: scm.camelize)
        end
      end
    end

    context 'with the default enabled scms' do
      it_behaves_like 'shows enabled scms'
    end

    context 'with only one enabled scm' do
      let(:enabled_scms) { %w[subversion] }
      it_behaves_like 'shows enabled scms'
      it 'does not show git' do
        expect(scm_vendor_input).not_to have_selector('option', text: 'Git')
      end
    end
  end

  describe 'with submitted vendor form' do
    before do
      settings_page.visit_repository_settings
      find("option[value='#{vendor}']").select_option
    end

    shared_examples 'has only the type which is selected' do |type, vendor|
      it 'should display one type' do
        # There seems to be an issue with how the
        # select is accessed after the async form loading
        # Thus we explitly find it here to allow some wait
        # even though it is available in let
        scm_vendor = find(scm_vendor_input_css)
        expect(scm_vendor.value).to eq(vendor)

        page.assert_selector('input[name="scm_type"]', count: 1)
        scm_type = find('input[name="scm_type"]')

        expect(scm_type.value).to eq(type)

        content = find("#"+"#{vendor}-#{type}", visible: false)
        expect(content).not_to be_nil
        scm_type.should be_checked
      end
    end

    shared_examples 'has hidden type' do |type, vendor|
      let(:selector) { find("input[name='scm_type'][value='#{type}']") }

      it 'should display a collapsed type' do
        expect(selector).not_to be_nil
        expect(selector[:selected]).to be_falsey
        expect(selector[:disabled]).to be_falsey

        content = find("#"+"#{vendor}-#{type}", visible: false)
        expect(content).not_to be_nil
        expect(content[:style]).to match("display: none")
      end
    end

    shared_examples 'has managed and other type' do |type, vendor|
      it_behaves_like 'has hidden type', type, vendor
      it_behaves_like 'has hidden type', 'managed', vendor

      it 'can toggle between the two' do
        find("input[name='scm_type'][value='#{type}']").set(true)
        content = find("#attributes-group--content-#{type}")
        expect(content).not_to be_nil
        expect(content[:hidden]).to be_falsey
        content = find("#"+"#{vendor}-#{type}", visible: false)
        expect(content).not_to be_nil
        expect(content[:style]).not_to match("display: none")

        find('input[type="radio"][value="managed"]').set(true)
        content = find('#attributes-group--content-managed')
        expect(content).not_to be_nil
        expect(content[:hidden]).to be_falsey
        content = find("#"+"#{vendor}-managed", visible: false)
        expect(content).not_to be_nil
        expect(content[:style]).not_to match("display: none")
      end
    end

    shared_examples 'it can create the managed repository' do
      it 'can complete the form without any parameters' do
        find('input[type="radio"][value="managed"]').set(true)

        click_button(I18n.t(:button_create))

        expect(page).to have_selector('div.flash.notice',
                                      text: I18n.t('repositories.create_successful'))
        expect(page).to have_selector('a.icon-delete', text: I18n.t(:button_delete))
      end
    end

    shared_examples 'it can create the repository of type with url' do |type, url|
      it 'can complete the form without any parameters' do
        find("input[type='radio'][value='#{type}']").set(true)
        find('input[name="repository[url]"]').set(url)

        click_button(I18n.t(:button_create))

        expect(page).to have_selector('div.flash.notice',
                                      text: I18n.t('repositories.create_successful'))
        expect(page).to have_selector('button[type="submit"]', text: I18n.t(:button_save))
        expect(page).to have_selector('a.icon-remove', text: I18n.t(:button_remove))
      end
    end

    context 'with Subversion selected' do
      let(:vendor) { 'subversion' }

      it_behaves_like 'has only the type which is selected', 'existing', 'subversion'

      context 'and managed repositories' do
        include_context 'with tmpdir'
        let(:config) {
          { subversion: { manages: tmpdir } }
        }
        it_behaves_like 'has managed and other type', 'existing', 'subversion'
        it_behaves_like 'it can create the managed repository'
        it_behaves_like 'it can create the repository of type with url',
                        'existing',
                        'file:///tmp/svn/foo.svn'
      end
    end

    context 'with Git selected' do
      let(:vendor) { 'git' }

      it_behaves_like 'has only the type which is selected', 'local', 'git'
      context 'and managed repositories, but not ours' do
        let(:config) {
          { subversion: { manages: '/tmp/whatever' } }
        }
        it_behaves_like 'has only the type which is selected', 'local', 'git'
      end

      context 'and managed repositories' do
        include_context 'with tmpdir'
        let(:config) {
          { git: { manages: tmpdir } }
        }

        it_behaves_like 'has managed and other type', 'local', 'git'
        it_behaves_like 'it can create the managed repository'
        it_behaves_like 'it can create the repository of type with url',
                        'local',
                        '/tmp/git/foo.git'
      end
    end

    describe 'remote managed repositories', webmock: true do
      let(:vendor) { 'git' }
      let(:url) { 'http://myreposerver.example.com/api/' }
      let(:config) {
        {
          git: { manages: url }
        }
      }

      before do
        stub_request(:post, url)
          .to_return(status: 200,
                     body: { success: true, url: 'file:///foo/bar' }.to_json)
      end

      it_behaves_like 'it can create the managed repository'
    end
  end
end
