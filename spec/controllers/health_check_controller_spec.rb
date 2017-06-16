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

describe HealthCheckController, type: :controller do
  describe '#application' do
    let(:request) { get :application }

    context 'when okay' do
      it 'returns 200 OK' do
        request

        expect(response.status).to eq(200)
        expect(response.body).to match /ALIVE/
      end
    end

    context 'when database error' do
      it 'returns 200 OK' do
        expect(controller).to receive(:send_db_ping).and_raise('ERROR!')

        request

        expect(response.status).to eq(500)
        expect(response.body).to match /ERROR/
      end
    end
  end

  describe '#jobs' do
    let(:request) { get :delayed_jobs }

    context 'when okay' do
      it 'returns 200 OK' do
        expect(Delayed::Job).to receive_message_chain(:where, :count).and_return 0

        request

        expect(response.status).to eq(200)
        expect(response.body).to be_empty
      end
    end

    context 'when unfinished jobs exist' do
      it 'returns 200 OK' do
        expect(Delayed::Job).to receive_message_chain(:where, :count).and_return 10

        request

        expect(response.status).to eq(500)
        expect(response.body).to include '10 delayed jobs were never executed.'
      end
    end
  end
end
