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

describe ::API::V3::Versions::VersionCollectionRepresenter do
  let(:self_link) { '/api/v3/projects/1/versions' }
  let(:versions) { FactoryBot.build_stubbed_list(:version, 3) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(versions, self_link, current_user: user) }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject(:collection) { representer.to_json }

    it_behaves_like 'unpaginated APIv3 collection', 3, 'projects/1/versions', 'Version'

    context '_links' do
      before do
        allow(user)
          .to receive(:allowed_to_globally?)
          .and_return(false)

        allow(user)
          .to receive(:allowed_to_globally?)
          .with(:manage_versions)
          .and_return(allowed_to)
      end

      describe 'createVersionImmediately' do
        context 'if the user is allowed to' do
          let(:allowed_to) { true }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'createVersionImmediately' }
            let(:href) { api_v3_paths.versions }
          end
        end

        context 'if the user is not allowed to' do
          let(:allowed_to) { false }

          it_behaves_like 'has no link' do
            let(:link) { 'createVersionImmediately' }
          end
        end
      end

      describe 'createVersion' do
        context 'if the user is allowed to' do
          let(:allowed_to) { true }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'createVersion' }
            let(:href) { api_v3_paths.create_version_form }
          end
        end

        context 'if the user is not allowed to' do
          let(:allowed_to) { false }

          it_behaves_like 'has no link' do
            let(:link) { 'createVersion' }
          end
        end
      end
    end
  end
end
