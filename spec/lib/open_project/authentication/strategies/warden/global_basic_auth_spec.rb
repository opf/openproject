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

Strategies = OpenProject::Authentication::Strategies::Warden

RSpec.describe Strategies::GlobalBasicAuth do
  let(:user) { "someuser" }
  let(:password) { "somepassword" }

  let(:config) do
    lambda do
      Strategies::GlobalBasicAuth.configure! user:, password:
    end
  end

  context "with UserBasicAuth's reserved username" do
    let(:user) { Strategies::UserBasicAuth.user }

    before do
      allow(Strategies::UserBasicAuth).to receive(:user).and_return("schluessel")
    end

    it "raises an error" do
      expect(&config).to raise_error("global user must not be 'schluessel'")
    end
  end

  context "with an empty pasword" do
    let(:password) { "" }

    it "raises an error" do
      expect(&config).to raise_error("password must not be empty")
    end
  end

  context "with digits-only password" do
    let(:password) { 1234 }
    let(:strategy) { Strategies::GlobalBasicAuth.new nil }

    before do
      config.call
    end

    it "must authenticate successfully" do
      expect(strategy.authenticate_user(user, "1234")).to be_truthy
    end
  end
end
