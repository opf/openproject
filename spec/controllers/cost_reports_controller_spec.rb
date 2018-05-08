#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostReportsController, type: :controller do
  include OpenProject::Reporting::PluginSpecHelper

  let(:user) { FactoryBot.build(:user) }
  let(:project) { FactoryBot.build(:valid_project) }

  describe "GET show" do
    before(:each) do
      is_member project, user, [:view_cost_entries]
      allow(User).to receive(:current).and_return(user)
    end

    describe "WHEN providing invalid units
              WHEN having the view_cost_entries permission" do
      before do
        get :show, params: { id: 1, unit: -1 }
      end

      it "should respond with a 404 error" do
        expect(response.code).to eql("404")
      end
    end
  end
end
