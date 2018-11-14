#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe HourlyRatesController do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:default_rate) { FactoryBot.create(:default_hourly_rate, user: user) }

  describe 'PUT update' do
    describe 'WHEN trying to update with an invalid rate value' do
      let(:params) {
        {
          id: user.id,
          user: { 'existing_rate_attributes' => { "#{default_rate.id}" => { 'valid_from' => "#{default_rate.valid_from}", 'rate' => '2d5' } } }
        }
      }
      before do
        as_logged_in_user admin do
          post :update, params: params
        end
      end

      it 'should render the edit template' do
        expect(response).to render_template('edit')
      end

      it 'should display an error message' do
        actual_message = assigns(:user).default_rates.first.errors.messages[:rate].first
        expect(actual_message).to eq(I18n.t('activerecord.errors.messages.not_a_number'))
      end
    end
  end
end
