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

describe 'Repository Settings', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create (:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:settings_page) { RepositorySettingsPage.new(project) }

  # Allow to override configuration values to determine
  # whether to activate managed repositories
  let(:enabled_scms) { %w[Subversion Git] }
  let(:config) { nil }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)

    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)

    allow(project).to receive(:repository).and_return(repository)
    settings_page.visit_repository_settings
  end

  shared_examples 'manages the repository' do |type|
    it 'displays the repository' do
      expect(page).not_to have_selector('select[name="scm_vendor"]')
      expect(find("#toggleable-attributes-group--content-#{type}", visible: true))
        .not_to be_nil
    end

    it 'deletes the repository' do
      expect(Repository.exists?(repository)).to be true
      find('a.icon-delete', text: I18n.t(:button_delete)).click

      # Confirm the notification warning
      warning = (type == 'managed') ? '-warning.-severe' : '-warning'
      expect(page).to have_selector(".notification-box.#{warning}")
      find('a', text: I18n.t(:button_delete)).click

      vendor = find('select[name="scm_vendor"]')
      expect(vendor).not_to be_nil
      expect(vendor.value).to be_empty

      selected = vendor.find('option[selected]')
      expect(selected.text).to eq('--- Please select ---')
      expect(selected[:disabled]).to be_truthy
      expect(selected[:selected]).to be_truthy

      # Project should have no repository
      expect(Repository.exists?(repository)).to be false
    end
  end

  shared_examples 'manages the repository with' do |name, type|
    let(:repository) {
      FactoryGirl.create("repository_#{name.downcase}".to_sym,
                         scm_type: type,
                         project: project)
    }
    it_behaves_like 'manages the repository', type
  end

  it_behaves_like 'manages the repository with', 'Subversion', 'existing'
  it_behaves_like 'manages the repository with', 'Git', 'local'

  context 'managed repositories' do
    include_context 'with tmpdir'
    let(:config) {
      {
        Subversion: { manages: File.join(tmpdir, 'svn') },
        Git:        { manages: File.join(tmpdir, 'git') }
      }
    }

    let(:repository) {
      repo = Repository.build(
        project,
        managed_vendor,
        # Need to pass AC params here manually to simulate a regular repository build
        ActionController::Parameters.new({}),
        :managed
      )

      repo.save!
      repo
    }

    context 'Subversion' do
      let(:managed_vendor) { 'Subversion' }
      it_behaves_like 'manages the repository', 'managed'
    end

    context 'Git' do
      let(:managed_vendor) { 'Git' }
      it_behaves_like 'manages the repository', 'managed'
    end
  end
end
