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

describe Authorization::LicenseService do
  let(:license_object) do
    license = OpenProject::License.new
    license.licensee = 'Foobar'
    license.mail = 'foo@example.org'
    license.starts_at = Date.today
    license.expires_at = nil

    license
  end
  let(:license) { mock_model(License, license_object: license_object) }
  let(:instance) { described_class.new(license) }
  let(:result) { instance.call(action) }
  let(:action) { :an_action }

  describe '#initialize' do
    it 'has the license' do
      expect(instance.license).to eql license
    end
  end

  describe 'expiry' do
    before do
      allow(license).to receive(:expired?).and_return(expired)
    end

    context 'when expired' do
      let(:expired) { true }

      it 'returns a false result' do
        expect(result).to be_kind_of ServiceResult
        expect(result.result).to be_falsey
        expect(result.success?).to be_falsey
      end
    end

    context 'when active' do
      let(:expired) { false }

      context 'invalid action' do
        it 'returns false' do
          expect(result.result).to be_falsey
        end
      end

      context 'valid action requires active license' do
        let(:action) { :define_custom_style }

        it 'returns a true result' do
          expect(result).to be_kind_of ServiceResult
          expect(result.result).to be_truthy
          expect(result.success?).to be_truthy
        end
      end
    end
  end
end
