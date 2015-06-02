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

shared_examples_for 'action link' do
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages, :edit_work_packages]) }
  let(:user) {
    FactoryGirl.create(:user, member_in_project: project,
                              member_through_role: role)
  }

  before { allow(User).to receive(:current).and_return(user) }

  it { expect(subject).not_to have_json_path("_links/#{action}/href") }

  describe 'with permission' do
    before do
      role.permissions << permission
      role.save!
    end

    it { expect(subject).to have_json_path("_links/#{action}/href") }
  end
end

shared_examples_for 'has a titled link' do
  it { is_expected.to be_json_eql(href.to_json).at_path("_links/#{link}/href") }
  it { is_expected.to be_json_eql(title.to_json).at_path("_links/#{link}/title") }
end

shared_examples_for 'has an untitled link' do
  it { is_expected.to be_json_eql(href.to_json).at_path("_links/#{link}/href") }
  it { is_expected.not_to have_json_path("_links/#{link}/title") }
end

shared_examples_for 'has an empty link' do
  it { is_expected.to be_json_eql(nil.to_json).at_path("_links/#{link}/href") }

  it 'has no embedded resource' do
    is_expected.not_to have_json_path("_embedded/#{link}")
  end
end

shared_examples_for 'has no link' do
  it { is_expected.not_to have_json_path("_links/#{link}") }

  it 'has no embedded resource' do
    is_expected.not_to have_json_path("_embedded/#{link}")
  end
end
