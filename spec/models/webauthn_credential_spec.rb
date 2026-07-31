# frozen_string_literal: true

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

RSpec.describe WebauthnCredential do
  let(:user) { create(:user) }
  let(:instance) do
    described_class.new(user:, external_id: "external-id", public_key: "public-key", name: "My passkey")
  end

  describe "#valid?" do
    subject { instance.valid? }

    it "succeeds with valid attributes" do
      expect(subject).to be_truthy
    end

    context "without an external_id" do
      before { instance.external_id = nil }

      it "fails" do
        expect(subject).to be_falsey
      end
    end

    context "with a duplicate external_id" do
      before do
        described_class.create!(user:, external_id: "external-id", public_key: "other-key", name: "Other")
      end

      it "fails" do
        expect(subject).to be_falsey
      end
    end

    context "without a public_key" do
      before { instance.public_key = nil }

      it "fails" do
        expect(subject).to be_falsey
      end
    end

    context "without a name" do
      before { instance.name = nil }

      it "fails" do
        expect(subject).to be_falsey
      end
    end
  end

  describe "#user" do
    it "is destroyed together with the user" do
      instance.save!

      expect { user.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
