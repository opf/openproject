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

RSpec.describe Users::SetAttributesService, "Integration", type: :model do
  shared_let(:input_user) { create(:user) }
  let(:actor) { build_stubbed(:admin) }

  let(:instance) do
    described_class.new model: input_user,
                        user: actor,
                        contract_class: Users::UpdateContract
  end

  subject { instance.call(params) }

  context "with a boolean castable preference" do
    let(:params) do
      { pref: { hide_mail: "0" } }
    end

    it "returns an error for that" do
      expect(subject.errors).to be_empty
    end
  end

  context "with an invalid parameter" do
    let(:params) do
      { pref: { workdays: "foobar" } }
    end

    it "returns an error for that" do
      expect(subject.errors[:workdays]).to include "is not of type 'array'"
    end
  end

  context "with an unknown property" do
    let(:params) do
      { pref: { watwatwat: "foobar" } }
    end

    it "does not raise an error" do
      expect(subject).to be_success
      expect(subject.result.pref.settings).not_to be_key(:watwatwat)
    end
  end
end
