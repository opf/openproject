#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe PermittedParams, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }

  describe '#search' do
    it 'permits its whitelisted params' do
      acceptable_params = { messages: 1 }

      permitted = ActionController::Parameters.new(acceptable_params).permit!
      params = ActionController::Parameters.new(acceptable_params)

      expect(PermittedParams.new(params, user).search).to eq(permitted)
    end
  end
end
