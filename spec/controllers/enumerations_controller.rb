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

describe EnumerationsController, type: :controller do
  before do allow(controller).to receive(:require_admin).and_return(true) end

  describe '#destroy' do
    describe '#priority' do
      let(:enum_to_delete) { FactoryBot.create(:priority_normal) }

      shared_examples_for 'successful delete' do
        it { expect(Enumeration.find_by(id: enum_to_delete.id)).to be_nil }

        it { expect(response).to redirect_to(enumerations_path) }
      end

      describe 'not in use' do
        before do
          post :destroy, params: { id: enum_to_delete.id }
        end

        it_behaves_like 'successful delete'
      end

      describe 'in use' do
        let!(:enum_to_reassign) { FactoryBot.create(:priority_high) }
        let!(:work_package) {
          FactoryBot.create(:work_package,
                             priority: enum_to_delete)
        }

        describe 'no reassign' do
          before do
            post :destroy, params: { id: enum_to_delete.id }
          end

          it { expect(assigns(:enumerations)).to include(enum_to_reassign) }

          it { expect(Enumeration.find_by(id: enum_to_delete.id)).not_to be_nil }

          it { expect(response).to render_template('enumerations/destroy') }
        end

        describe 'reassign' do
          before do
            post :destroy,
                 params: { id: enum_to_delete.id, reassign_to_id: enum_to_reassign.id }
          end

          it_behaves_like 'successful delete'
        end
      end
    end
  end
end
