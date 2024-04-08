#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe StatusesController do
  shared_let(:user) { create(:admin) }
  shared_let(:status) { create(:status) }

  before { login_as(user) }

  shared_examples_for "responds successfully" do |template:|
    subject { response }

    it { is_expected.to be_successful }

    it { is_expected.to render_template(template) }
  end

  shared_examples_for "redirects to index page" do
    subject { response }

    it { is_expected.to redirect_to(action: :index) }
  end

  describe "#index" do
    before { get :index }

    it_behaves_like "responds successfully", template: "index"
  end

  describe "#new" do
    before { get :new }

    it_behaves_like "responds successfully", template: "new"
  end

  describe "#create" do
    let(:name) { "New Status" }

    before do
      post :create,
           params: { status: { name: } }
    end

    it "creates a new status" do
      expect(Status.find_by(name:)).not_to be_nil
    end

    it_behaves_like "redirects to index page"
  end

  describe "#edit" do
    context "when status is the default one" do
      let!(:status_default) do
        create(:status,
               is_default: true)
      end

      before do
        get :edit,
            params: { id: status_default.id }
      end

      it_behaves_like "responds successfully", template: "edit"

      describe "#view" do
        render_views

        it do
          assert_select "p",
                        { content: Status.human_attribute_name(:is_default) },
                        false
        end
      end
    end

    context "when status is not the default one" do
      before do
        status

        get :edit, params: { id: status.id }
      end

      it_behaves_like "responds successfully", template: "edit"

      describe "#view" do
        render_views

        it do
          assert_select "div",
                        content: Status.human_attribute_name(:is_default)
        end
      end
    end
  end

  describe "#update" do
    let(:name) { "Renamed Status" }

    before do
      status

      patch :update,
            params: {
              id: status.id,
              status: { name: }
            }
    end

    it "updates the status with new values" do
      expect(Status.find_by(name:)).not_to be_nil
    end

    it_behaves_like "redirects to index page"
  end

  describe "#destroy" do
    let(:name) { status.name }

    context "when destroying an unused status" do
      before do
        delete :destroy, params: { id: status.id }
      end

      after do
        Status.delete_all
      end

      it "is destroyed" do
        expect(Status.find_by(name:)).to be_nil
      end

      it_behaves_like "redirects to index page"
    end

    context "when destroying a status used by a work package" do
      let(:work_package) do
        create(:work_package,
               status:)
      end

      before do
        work_package

        delete :destroy, params: { id: status.id }
      end

      it "can not delete it" do
        expect(Status.find_by(name:)).not_to be_nil
      end

      it "display a flash error message" do
        expect(flash[:error]).to eq(I18n.t("error_unable_delete_status"))
      end

      it_behaves_like "redirects to index page"
    end

    context "when destroying the default status" do
      let!(:status_default) do
        create(:status,
               is_default: true)
      end

      before do
        delete :destroy, params: { id: status_default.id }
      end

      it "can not delete it" do
        expect(Status.find_by(name:)).not_to be_nil
      end

      it "shows the right flash message" do
        expect(flash[:error]).to eq(I18n.t("error_unable_delete_default_status"))
      end

      it_behaves_like "redirects to index page"
    end
  end

  describe "#update_work_package_done_ratio" do
    context "with 'work_package_done_ratio' using 'field'" do
      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return "field"

        post :update_work_package_done_ratio
      end

      it { is_expected.to set_flash[:error].to(I18n.t("error_work_package_done_ratios_not_updated")) }

      it_behaves_like "redirects to index page"
    end

    context "with 'work_package_done_ratio' using 'status'" do
      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return "status"

        post :update_work_package_done_ratio
      end

      it { is_expected.to set_flash[:notice].to(I18n.t("notice_work_package_done_ratios_updated")) }

      it_behaves_like "redirects to index page"
    end
  end
end
