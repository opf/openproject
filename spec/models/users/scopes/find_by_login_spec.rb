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

RSpec.describe Users::Scopes::FindByLogin do
  let!(:activity) { create(:time_entry_activity) }
  let!(:project) { create(:project) }
  let!(:user) { create(:user, login:) }
  let(:login) { "Some string" }
  let(:search_login) { login }

  describe ".find_by_login" do
    subject { User.find_by_login(search_login) }

    context "with the exact same login" do
      it "returns the user" do
        expect(subject)
          .to eql user
      end
    end

    context "with a non existing login" do
      let(:search_login) { "nothing" }

      it "returns nil" do
        expect(subject)
          .to be_nil
      end
    end

    context "with a lowercase login" do
      let(:search_login) { login.downcase }

      it "returns the user with the matching login" do
        expect(subject)
          .to eql user
      end
    end
  end
end
