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

describe ::API::V3::CustomActions::CustomActionExecuteRepresenter, 'parsing' do
  include ::API::V3::Utilities::PathHelper

  let(:struct) { OpenStruct.new }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:work_package) { FactoryBot.build_stubbed(:stubbed_work_package) }

  let(:representer) do
    described_class.new(struct, current_user: user)
  end

  let(:payload) do
    {}
  end

  subject do
    representer.from_hash(payload)

    struct
  end

  context 'lockVersion' do
    let(:payload) do
      {
        'lockVersion' => 1
      }
    end

    it 'sets the lockVersion' do
      expect(subject.lock_version)
        .to eql payload['lockVersion']
    end
  end

  context '_links' do
    context 'workPackage' do
      let(:payload) do
        {
          '_links' => {
            'workPackage' => {
              'href' => api_v3_paths.work_package(work_package.id)
            }
          }
        }
      end

      it 'sets the work_package_id' do
        expect(subject.work_package_id)
          .to eql work_package.id.to_s
      end
    end
  end
end
