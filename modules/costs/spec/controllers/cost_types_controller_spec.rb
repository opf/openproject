#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")

RSpec.describe CostTypesController do
  let(:admin)     { create(:admin) }
  let(:cost_type) { create(:cost_type) }

  describe "DELETE destroy" do
    it "allows an admin to delete" do
      as_logged_in_user admin do
        delete :destroy, params: { id: cost_type.id }
      end

      expect(assigns(:cost_type).deleted_at).to be_a Time
      expect(response).to redirect_to cost_types_path
      expect(flash[:notice]).to eq I18n.t(:notice_successful_lock)
    end
  end

  describe "PATCH restore" do
    before do
      cost_type.deleted_at = DateTime.now
    end

    it "allows an admin to restore" do
      as_logged_in_user admin do
        patch :restore, params: { id: cost_type.id }
      end

      expect(assigns(:cost_type).deleted_at).to be_nil
      expect(response).to redirect_to cost_types_path
      expect(flash[:notice]).to eq I18n.t(:notice_successful_restore)
    end
  end
end
