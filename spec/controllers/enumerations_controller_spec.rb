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

require "spec_helper"

RSpec.describe EnumerationsController do
  shared_let(:admin) { create(:admin) }

  current_user do
    admin
  end

  describe "#index" do
    before do
      get :index
    end

    it "is successful" do
      expect(response)
        .to have_http_status(:ok)
    end

    it "renders the index template" do
      expect(response)
        .to render_template "index"
    end
  end

  describe "#destroy" do
    let(:enum) { create(:priority) }
    let(:params) { { id: enum.id } }
    let(:work_packages) { [] }

    before do
      work_packages

      delete :destroy, params:
    end

    it "redirects" do
      expect(response)
        .to redirect_to enumerations_path
    end

    it "destroys the enum" do
      expect(Enumeration.where(id: enum.id))
        .not_to exist
    end

    context "when in use" do
      let(:work_packages) { [create(:work_package, priority: enum)] }

      it "keeps the enum (as it needs to be reassigned)" do
        expect(Enumeration.where(id: enum.id))
          .to exist
      end

      it "keeps the usage" do
        expect(work_packages.first.reload.priority)
          .to eql enum
      end

      it "renders destroy template" do
        expect(response)
          .to render_template :destroy
      end
    end

    context "when in use and reassigning" do
      let(:work_packages) { [create(:work_package, priority: enum)] }
      let!(:other_enum) { create(:priority) }
      let(:params) { { id: enum.id, reassign_to_id: other_enum.id } }

      it "destroys the enum" do
        expect(Enumeration.where(id: enum.id))
          .not_to exist
      end

      it "reassigns the usage" do
        expect(work_packages.first.reload.priority)
          .to eql other_enum
      end
    end
  end
end
