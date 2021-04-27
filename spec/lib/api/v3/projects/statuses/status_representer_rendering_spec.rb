#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Projects::Statuses::StatusRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  subject { representer.to_json }

  let(:status) { Projects::Status.codes.keys.first }
  let(:representer) do
    described_class.create(status, current_user: current_user, embed_links: true)
  end

  current_user { FactoryBot.build_stubbed(:user) }

  describe '_links' do
    describe 'self' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.project_status status }
        let(:title) { I18n.t(:"activerecord.attributes.projects/status.codes.#{status}") }
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'ProjectStatus' }
    end

    it_behaves_like 'property', :id do
      let(:value) { status }
    end

    it_behaves_like 'property', :name do
      let(:value) { I18n.t(:"activerecord.attributes.projects/status.codes.#{status}") }
    end
  end
end
