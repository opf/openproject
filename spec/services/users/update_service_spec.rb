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

require "spec_helper"
require "services/base_services/behaves_like_update_service"

RSpec.describe Users::UpdateService do
  it_behaves_like "BaseServices update service" do
    # The user service also tries to save the preferences
    before do
      allow(model_instance.pref).to receive(:save).and_return(true)
    end
  end

  describe "updating attributes" do
    let(:instance) { described_class.new(model: update_user, user: current_user) }
    let(:current_user) { create(:admin) }
    let(:update_user) { create(:user, mail: "correct@example.org") }

    subject { instance.call(attributes:) }

    context "when invalid" do
      let(:attributes) { { mail: "invalid" } }

      it "fails to update" do
        expect(subject).not_to be_success

        update_user.reload
        expect(update_user.mail).to eq("correct@example.org")

        expect(subject.errors.symbols_for(:mail)).to match_array(%i[email])
      end
    end

    context "when valid" do
      let(:attributes) { { mail: "new@example.org" } }

      it "updates the user" do
        expect(subject).to be_success

        update_user.reload
        expect(update_user.mail).to eq("new@example.org")
      end

      context "if current_user is no admin" do
        let(:current_user) { build_stubbed(:user) }

        it "is unsuccessful" do
          expect(subject).not_to be_success
        end
      end
    end

    context "when valid status" do
      let(:attributes) { { status: Principal.statuses[:locked] } }

      it "updates the user" do
        expect(subject).to be_success

        update_user.reload
        expect(update_user).to be_locked
      end

      context "if current_user is no admin" do
        let(:current_user) { build_stubbed(:user) }

        it "is unsuccessful" do
          expect(subject).not_to be_success
        end
      end
    end

    describe "updating prefs" do
      let(:attributes) { {} }

      before do
        allow(update_user).to receive(:save).and_return(user_save_result)
      end

      context "if the user was updated calls the prefs" do
        let(:user_save_result) { true }

        before do
          expect(update_user.pref).to receive(:save).and_return(pref_save_result)
        end

        context "and the prefs can be saved" do
          let(:pref_save_result) { true }

          it "returns a successful call" do
            expect(subject).to be_success
          end
        end

        context "and the prefs can not be saved" do
          let(:pref_save_result) { false }

          it "returns an erroneous call" do
            expect(subject).not_to be_success
          end
        end
      end

      context "if the user was not saved" do
        let(:user_save_result) { false }

        it "does not call #prefs.save" do
          expect(update_user.pref).not_to receive(:save)
          expect(subject).not_to be_success
        end
      end
    end
  end
end
