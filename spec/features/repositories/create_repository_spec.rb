#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
require 'features/repositories/repository_settings_page'

describe 'Create repository', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create (:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:settings_page) { RepositorySettingsPage.new(project) }

  # Allow to override configuration values to determine
  # whether to activate managed repositories
  let(:enabled_scms) { %w[Subversion Git] }
  let(:config) { nil }

  let(:scm_vendor_input) { find('select[name="scm_vendor"]') }

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
          expect(scm_vendor_input).to have_selector('option', text: scm)
        end
      end
    end

    context 'with the default enabled scms' do
      it_behaves_like 'shows enabled scms'
    end

    context 'with only one enabled scm' do
      let(:enabled_scms) { %w[Subversion] }
      it_behaves_like 'shows enabled scms'
      it 'does not show git' do
        expect(scm_vendor_input).not_to have_selector('option', text: 'Git')
      end
    end
  end

  describe 'with submitted vendor form' do
    let(:scm_types) { page.all('input[name="scm_type"]') }
    before do
      settings_page.visit_repository_settings
      scm_vendor_input.find('option', text: vendor).select_option
    end

    shared_examples "displays only the type" do |type|
      it 'should display one type, but expanded' do
        expect(scm_vendor_input.value).to eq(vendor)
        expect(scm_types.length).to eq(1)
        expect(scm_types[0].value).to eq(type)
        expect(scm_types[0][:selected]).to be_truthy
        expect(scm_types[0][:disabled]).to be_falsey

        content = find("#toggleable-attribute-group--content-#{type}")
        expect(content).not_to be_nil
        expect(content[:hidden]).to be_falsey
      end
    end

    shared_examples 'displays collapsed type' do |type|
      let(:selector) { find("input[name='scm_type'][value='#{type}']") }

      it 'should display a collapsed type' do
        expect(selector).not_to be_nil
        expect(selector[:selected]).to be_falsey
        expect(selector[:disabled]).to be_falsey

        content = find("#toggleable-attribute-group--content-#{type}", visible: false)
        expect(content).not_to be_nil
        expect(content[:hidden]).to be_truthy
      end
    end

    shared_examples 'has managed and other type' do |type|
      it_behaves_like 'displays collapsed type', type
      it_behaves_like 'displays collapsed type', 'managed'

      it 'can toggle between the two' do
        find("input[name='scm_type'][value='#{type}']").set(true)
        content = find("#toggleable-attribute-group--content-#{type}")
        expect(content).not_to be_nil
        expect(content[:hidden]).to be_falsey

        find('input[type="radio"][value="managed"]').set(true)
        content = find("#toggleable-attribute-group--content-managed")
        expect(content).not_to be_nil
        expect(content[:hidden]).to be_falsey
      end
    end

    shared_examples 'it can create the managed repository' do
      it 'can complete the form without any parameters' do
        find('input[type="radio"][value="managed"]').set(true)
        find('button[type="submit"]', text: I18n.t(:button_create)).click

        expect(page).to have_selector('button', text: I18n.t(:button_save))
        expect(page).to have_selector('a.icon-delete', text: I18n.t(:button_delete))
      end
    end

    shared_examples 'it can create the repository of type with url' do |type, url|
      it 'can complete the form without any parameters' do
        find("input[type='radio'][value='#{type}']").set(true)
        find('input[name="repository[url]"]').set(url)

        find('button[type="submit"]', text: I18n.t(:button_create)).click

        expect(page).to have_selector('button[type="submit"]', text: I18n.t(:button_save))
        expect(page).to have_selector('a.icon-delete', text: I18n.t(:button_delete))
      end
    end

    context 'with Subversion selected' do
      let(:vendor) { 'Subversion' }

      it_behaves_like 'displays only the type', 'existing'

      context 'and managed repositories' do
        Dir.mktmpdir do |dir|
          let(:config) {
            { Subversion: { manages: dir } }
          }
          it_behaves_like 'has managed and other type', 'existing'
          it_behaves_like 'it can create the managed repository'
          it_behaves_like 'it can create the repository of type with url',
                          'existing',
                          'file:///tmp/svn/foo.svn'
        end
      end
    end

    context 'with Git selected' do
      let(:vendor) { 'Git' }

      it_behaves_like 'displays only the type', 'local'
      context 'and managed repositories, but not ours' do
        let(:config) {
          { Subversion: { manages: '/tmp/whatever' } }
        }
        it_behaves_like 'displays only the type', 'local'
      end

      context 'and managed repositories' do
        Dir.mktmpdir do |dir|
          let(:config) {
            { Git: { manages: dir } }
          }

          it_behaves_like 'has managed and other type', 'local'
          it_behaves_like 'it can create the managed repository'
          it_behaves_like 'it can create the repository of type with url',
                          'local',
                          '/tmp/git/foo.git'
        end
      end
    end
  end
end
