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
    let(:status_params) { { name: } }

    before do
      patch :update,
            params: {
              id: status.id,
              status: status_params
            }
    end

    it "updates the status with new values" do
      expect(Status.find_by(name:)).not_to be_nil
    end

    it_behaves_like "redirects to index page"

    context "when in work-based mode when changing the default % complete",
            with_settings: { work_package_done_ratio: "field" } do
      let(:new_default_done_ratio) { 40 }
      let(:status_params) { { default_done_ratio: new_default_done_ratio } }

      it "does not start any jobs to update work packages % complete values" do
        expect(status.reload).to have_attributes(default_done_ratio: new_default_done_ratio)
        expect(WorkPackages::Progress::ApplyStatusesChangeJob)
          .not_to have_been_enqueued
      end

      context "when also marking a status as excluded from totals calculations" do
        before_all do
          status.update_columns(name: "Rejected",
                                default_done_ratio: 70)
        end

        shared_let(:status_new) { create(:status, name: "New", default_done_ratio: "0") }
        shared_let_work_packages(<<~TABLE)
          hierarchy     | status   | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          parent        | New      |      |                |            |    20h |              15h |          25%
            child       | Rejected |  10h |             5h |        50% |        |                  |
            other child | New      |  10h |            10h |         0% |        |                  |
        TABLE

        let(:status_params) do
          { default_done_ratio: new_default_done_ratio,
            excluded_from_totals: true }
        end

        it "starts a job to update totals of work packages having excluded children" do
          expect(status.reload).to have_attributes(excluded_from_totals: true)
          expect(WorkPackages::Progress::ApplyStatusesChangeJob)
            .to have_been_enqueued.with(cause_type: "status_changed",
                                        status_name: status.name,
                                        status_id: status.id,
                                        changes: { "excluded_from_totals" => [false, true] })

          perform_enqueued_jobs

          expect_work_packages([parent, child, other_child], <<~TABLE)
            subject       | status   | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent        | New      |      |                |            |    10h |              10h |           0%
              child       | Rejected |  10h |             5h |        50% |        |                  |
              other child | New      |  10h |            10h |         0% |        |                  |
          TABLE
          expect(parent.last_journal.details["cause"].last).to include("type" => "status_changed")
        end
      end
    end

    context "when in status-based mode",
            with_settings: { work_package_done_ratio: "status" } do
      context "when changing the default % complete" do
        shared_let(:work_package) { create(:work_package, status:) }
        let(:new_default_done_ratio) { 40 }
        let(:status_params) { { default_done_ratio: new_default_done_ratio } }

        it "starts a job to update work packages % complete values" do
          old_default_done_ratio = status.default_done_ratio
          expect(status.reload).to have_attributes(default_done_ratio: new_default_done_ratio)
          expect(WorkPackages::Progress::ApplyStatusesChangeJob)
            .to have_been_enqueued.with(cause_type: "status_changed",
                                        status_name: status.name,
                                        status_id: status.id,
                                        changes: { "default_done_ratio" => [old_default_done_ratio, new_default_done_ratio] })

          perform_enqueued_jobs

          expect(work_package.reload.read_attribute(:done_ratio)).to eq(new_default_done_ratio)
          expect(work_package.last_journal.details["cause"].last).to include("type" => "status_changed")
        end
      end

      context "when changing to the same default % complete value" do
        let(:status_params) { { default_done_ratio: status.default_done_ratio } }

        it "does not start any jobs" do
          expect(WorkPackages::Progress::ApplyStatusesChangeJob)
            .not_to have_been_enqueued
        end
      end

      context "when marking a status as excluded from totals calculations" do
        before_all do
          status.update_columns(name: "Rejected",
                                default_done_ratio: 70)
        end

        shared_let(:status_new) { create(:status, name: "New", default_done_ratio: "0") }
        shared_let_work_packages(<<~TABLE)
          hierarchy     | status   | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          parent        | New      |      |                |         0% |    20h |              16h |          20%
            child       | Rejected |  10h |             3h |        70% |        |                  |
            other child | New      |  10h |            10h |         0% |        |                  |
        TABLE

        let(:status_params) { { excluded_from_totals: true } }

        it "starts a job to update totals of work packages having excluded children" do
          expect(status.reload).to have_attributes(excluded_from_totals: true)
          expect(WorkPackages::Progress::ApplyStatusesChangeJob)
            .to have_been_enqueued.with(cause_type: "status_changed",
                                        status_name: status.name,
                                        status_id: status.id,
                                        changes: { "excluded_from_totals" => [false, true] })

          perform_enqueued_jobs

          expect_work_packages([parent, child, other_child], <<~TABLE)
            subject       | status   | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent        | New      |      |                |         0% |    10h |              10h |           0%
              child       | Rejected |  10h |             3h |        70% |        |                  |
              other child | New      |  10h |            10h |         0% |        |                  |
          TABLE
          expect(parent.last_journal.details["cause"].last).to include("type" => "status_changed")
        end

        context "when also changing the default % complete of the status" do
          let(:new_default_done_ratio) { 40 }
          let(:status_params) { { excluded_from_totals: true, default_done_ratio: new_default_done_ratio } }

          it "starts a job to update both total values and % complete of work packages" do
            old_default_done_ratio = status.default_done_ratio
            expect(status.reload).to have_attributes(default_done_ratio: new_default_done_ratio,
                                                     excluded_from_totals: true)
            expect(WorkPackages::Progress::ApplyStatusesChangeJob)
              .to have_been_enqueued.with(cause_type: "status_changed",
                                          status_name: status.name,
                                          status_id: status.id,
                                          changes: { "default_done_ratio" => [old_default_done_ratio, new_default_done_ratio],
                                                     "excluded_from_totals" => [false, true] })

            perform_enqueued_jobs

            expect_work_packages([parent, child, other_child], <<~TABLE)
              subject       | status   | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
              parent        | New      |      |                |         0% |    10h |              10h |           0%
                child       | Rejected |  10h |             6h |        40% |        |                  |
                other child | New      |  10h |            10h |         0% |        |                  |
            TABLE

            [parent, child].each do |work_package|
              expect(work_package.journals.count).to eq(2)
              expect(work_package.last_journal.details["cause"].last).to include("type" => "status_changed")
            end
            expect(other_child.journals.count).to eq(1) # this one should not have changed
          end
        end
      end

      context "when changing something else than default % complete or exclude from totals" do
        let(:status_params) { { name: "Another status name" } }

        it "does not start any jobs" do
          expect(WorkPackages::Progress::ApplyStatusesChangeJob)
            .not_to have_been_enqueued
        end
      end
    end
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
      shared_let(:work_package) do
        create(:work_package,
               status:)
      end

      before do
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
      shared_let(:status_default) do
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
end
