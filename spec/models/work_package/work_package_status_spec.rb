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

describe WorkPackage, 'status', type: :model do
  let(:status) { FactoryBot.create(:status) }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                      status: status)
  end

  describe '#readonly' do
    let(:status) { FactoryBot.create(:status, is_readonly: true) }

    context 'with EE', with_ee: %i[readonly_work_packages] do
      it 'marks work package as read only' do
        expect(work_package).to be_readonly_status
      end
    end

    context 'without EE' do
      it 'is not marked as read only' do
        expect(work_package).not_to be_readonly_status
      end
    end
  end
end
