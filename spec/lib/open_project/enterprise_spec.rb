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
require 'open_project/passwords'

describe OpenProject::Enterprise, :with_clean_fixture do
  describe "#user_limit_reached?" do
    let(:user_limit) { 2 }
    let(:builtin_user_count) { 2 }

    before do
      # create 3 built-in users, only 2 of which are active
      User.system
      User.anonymous
      DeletedUser.first # locked, not active

      allow(OpenProject::Enterprise).to receive(:user_limit).and_return(user_limit)
    end

    context "with fewer active users than the limit allows" do
      before do
        FactoryBot.create :user

        expect(User.active.count).to eq 1 + builtin_user_count # created user + built-in ones
      end

      it "is false" do
        expect(subject).not_to be_user_limit_reached
      end
    end

    context "with equal or more active users than the limit allows" do
      shared_examples "user limit is reached" do
        let(:num_active_users) { 0 }

        before do
          FactoryBot.create_list :user, num_active_users

          expect(User.active.count).to eq num_active_users + builtin_user_count
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
end
