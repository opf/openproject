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
require "open_project/passwords"

RSpec.describe OpenProject::Enterprise do
  # create 3 built-in users, only 2 of which are active
  # Also create a placeholder user which will not count against the limit
  let!(:system_user) { User.system }
  let!(:anonymous_user) { User.anonymous }
  let!(:deleted_user) { DeletedUser.first } # locked, not active
  let!(:placeholder_user) { create(:placeholder_user) }

  let(:user_limit) { 2 }

  before do
    allow(OpenProject::Enterprise)
      .to receive(:user_limit)
      .and_return(user_limit)
  end

  describe "#user_limit_reached?" do
    context "with fewer active users than the limit allows" do
      before do
        create(:user)

        expect(User.active.count).to eq 1 # created user
      end

      it "is false" do
        expect(subject).not_to be_user_limit_reached
      end
    end

    context "with equal or more active users than the limit allows" do
      shared_examples "user limit is reached" do
        let(:num_active_users) { 0 }

        before do
          create_list(:user, num_active_users)

          expect(User.active.count).to eq num_active_users
        end

        it "is true" do
          expect(subject).to be_user_limit_reached
        end
      end

      context "(equal)" do
        it_behaves_like "user limit is reached" do
          let(:num_active_users) { user_limit }
        end
      end

      context "(more)" do
        it_behaves_like "user limit is reached" do
          let(:num_active_users) { user_limit + 1 }
        end
      end
    end
  end

  describe "#imminent_user_limit?" do
    context "with the number of active + invited users below (or at) the user limit" do
      shared_examples "user limit is not imminent" do
        let(:num_invited_users) { 0 }

        before do
          create(:user)
          create_list(:invited_user, num_invited_users)

          expect(User.human.not_locked.count).to eq num_invited_users + 1
        end

        it "is true" do
          expect(subject).not_to be_imminent_user_limit
        end
      end

      context "(less)" do
        it_behaves_like "user limit is not imminent" do
          let(:num_invited_users) { 0 }
        end
      end

      context "(equal)" do
        it_behaves_like "user limit is not imminent" do
          let(:num_invited_users) { 1 }
        end
      end
    end

    context "with the number of active + invited users over the user limit" do
      before do
        create(:user)
        create_list(:invited_user, user_limit)
      end

      it "is true" do
        expect(subject).to be_imminent_user_limit
      end
    end
  end
end
