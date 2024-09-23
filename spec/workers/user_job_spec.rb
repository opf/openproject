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

RSpec.describe UserJob do
  let(:test_job) do
    Class.new(UserJob) do
      def execute(foo:)
        [user.id, User.current.id, user.admin]
      end
    end
  end

  subject do
    test_job.new(user:, foo: "foo").perform_now
  end

  describe "with system user" do
    let(:user) { User.system }

    it "uses that user" do
      given_user, current_user, admin = subject
      expect(given_user).to eq current_user
      expect(given_user).to eq user.id
      expect(admin).to be true
    end
  end

  describe "with a regular user" do
    let(:user) { build_stubbed(:user) }

    it "uses that user" do
      given_user, current_user, admin = subject
      expect(given_user).to eq current_user
      expect(given_user).to eq user.id
      expect(admin).to be false
    end
  end
end
