#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::Util do
  describe '.basic_auth_header' do
    subject { described_class.basic_auth_header(username, password) }

    context 'when password is more than 60 symbols' do
      let(:username) { 'Dart Scuadron' }
      let(:password) { "#{'StarWars' * 10}Forever!" }

      it 'has no newline characters in encoded string' do
        expect(subject['Authorization']).not_to match(/\n/)
        expect(subject).to eq(
          {
            "Authorization" => "Basic RGFydCBTY3VhZHJvbjpTdGFyV2Fyc1N0YXJXYXJzU3Rhcl" \
                               "dhcnNTdGFyV2Fyc1N0YXJXYXJzU3RhcldhcnNTdGFyV2Fyc1N0YX" \
                               "JXYXJzU3RhcldhcnNTdGFyV2Fyc0ZvcmV2ZXIh"
          }
        )
      end
    end
  end
end
