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

describe ::API::V3::News::NewsRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:news) do
    FactoryBot.build_stubbed(:news,
                             project: project,
                             author: user)
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.create(news, current_user: user, embed_links: true)
  end
  let(:permissions) { all_permissions }
  let(:all_permissions) { %i() }

  subject { representer.to_json }

  describe '_links' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.news news.id }
      let(:title) { news.title }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { :project }
      let(:title) { project.name }
      let(:href) { api_v3_paths.project project.id }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { :author }
      let(:title) { user.name }
      let(:href) { api_v3_paths.user user.id }
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'News' }
    end

    it_behaves_like 'property', :id do
      let(:value) { news.id }
    end

    it_behaves_like 'property', :title do
      let(:value) { news.title }
    end

    it_behaves_like 'property', :summary do
      let(:value) { news.summary }
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { news.created_at }
      let(:json_path) { 'createdAt' }
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { news.updated_at }
      let(:json_path) { 'updatedAt' }
    end

    it_behaves_like 'API V3 formattable', 'description' do
      let(:format) { 'markdown' }
      let(:raw) { news.description }
      let(:html) { '<p>' + news.description + '</p>' }
    end
  end

  describe '_embedded' do
    it 'has project embedded' do
      expect(subject)
        .to be_json_eql(project.name.to_json)
        .at_path('_embedded/project/name')
    end

    it 'has author embedded' do
      expect(subject)
        .to be_json_eql(user.name.to_json)
        .at_path('_embedded/author/name')
    end
  end
end
