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

describe 'Create repository', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create (:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:enabled_scms) { %w[git] }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)
    allow(Setting).to receive(:repository_checkout_data).and_return(checkout_data)

    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)
  end

  context 'managed repositories' do
    include_context 'with tmpdir'
    let(:config) {
      {
        git: { manages: File.join(tmpdir, 'git') }
      }
    }
    let(:checkout_data) {
      { 'git' => { 'enabled' => '1', 'base_url' => 'http://localhost/git/' } }
    }

    let!(:repository) {
      repo = FactoryGirl.build(:repository_git, scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)
      repo.save!

      repo
    }

    it 'toggles checkout instructions' do
      visit project_repository_path(project)

      expect(page).to have_selector('#repository--checkout-instructions')
      expect(page).to have_selector('#repository--checkout-instructions-toggle.-pressed')

      button = find('#repository--checkout-instructions-toggle')
      button.click

      expect(page).not_to have_selector('#repository--checkout-instructions')
      expect(page).not_to have_selector('#repository--checkout-instructions-toggle.-pressed')
    end
  end
end
