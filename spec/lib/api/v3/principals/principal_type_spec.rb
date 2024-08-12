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

RSpec.describe API::V3::Principals::PrincipalType do
  let(:principal) { nil }

  subject { described_class.for(instance) }

  shared_examples "returns api type" do |type|
    it do
      expect(subject).to eq type
    end
  end

  describe "with a user" do
    let(:instance) { build_stubbed(:user) }

    it_behaves_like "returns api type", :user
  end

  describe "with a user" do
    let(:instance) { build_stubbed(:user) }

    it_behaves_like "returns api type", :user
  end

  describe "with a system user" do
    let(:instance) { User.system }

    it_behaves_like "returns api type", :user
  end

  describe "with a system user" do
    let(:instance) { build_stubbed(:deleted_user) }

    it_behaves_like "returns api type", :user
  end

  describe "with anonymous" do
    let(:instance) { User.anonymous }

    it_behaves_like "returns api type", :user
  end

  describe "with a group" do
    let(:instance) { build_stubbed(:group) }

    it_behaves_like "returns api type", :group
  end

  describe "with a placeholder" do
    let(:instance) { build_stubbed(:placeholder_user) }

    it_behaves_like "returns api type", :placeholder_user
  end

  describe "with an invalid type" do
    let(:instance) { "whatever" }

    it "raises an exception" do
      expect { subject }.to raise_error "undefined subclass for whatever"
    end
  end
end
