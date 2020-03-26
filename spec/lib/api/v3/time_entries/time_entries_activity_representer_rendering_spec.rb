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

describe ::API::V3::TimeEntries::TimeEntriesActivityRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:activity) do
    FactoryBot.build_stubbed(:time_entry_activity)
  end
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.new(activity, current_user: user, embed_links: true)
  end

  subject { representer.to_json }

  describe '_links' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.time_entries_activity activity.id }
      let(:title) { activity.name }
    end

    # returns the projects where it (and it's children) is active
    it_behaves_like 'has a link collection' do
      let(:project1) { FactoryBot.build_stubbed(:project) }
      let(:project2) { FactoryBot.build_stubbed(:project) }

      before do
        allow(::Projects::Scopes::VisibleWithActivatedTimeActivity)
          .to receive(:fetch)
          .with(activity)
          .and_return([project1,
                       project2])
      end

      let(:link) { 'projects' }
      let(:hrefs) do
        [
          {
            href: api_v3_paths.project(project1.identifier),
            title: project1.name
          },
          {
            href: api_v3_paths.project(project2.identifier),
            title: project2.name
          }
        ]
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'TimeEntriesActivity' }
    end

    it_behaves_like 'property', :id do
      let(:value) { activity.id }
    end

    it_behaves_like 'property', :name do
      let(:value) { activity.name }
    end

    it_behaves_like 'property', :position do
      let(:value) { activity.position }
    end

    it_behaves_like 'property', :default do
      let(:value) { activity.is_default }
    end
  end
end
