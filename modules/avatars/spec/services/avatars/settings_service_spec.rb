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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../spec_helper"

RSpec.describe Avatars::SettingsService do
  let(:user) { create(:user) }
  let(:principal) { user }
  let(:service) { described_class.new(principal:, user:) }

  before do
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return true
  end

  shared_examples "avatar settings with an image" do
    it "saves the image, source, and background together" do
      file = Rack::Test::UploadedFile.new(File.expand_path("../../fixtures/valid.jpg", __dir__), "image/jpeg")
      result = service.call(attributes: { avatar_type: "image", avatar_color: "#abc" }, file:)

      expect(result).to be_success
      expect(principal.reload.avatar_type).to eq "image"
      expect(principal.avatar_color).to eq "#AABBCC"
      expect(principal.local_avatar_attachment).to be_present
    end

    it "rolls back the source and color when an image is rejected" do
      file = Rack::Test::UploadedFile.new(File.expand_path("../../fixtures/invalid.txt", __dir__), "text/plain")
      result = service.call(attributes: { avatar_type: "image", avatar_color: "#abc" }, file:)

      expect(result).not_to be_success
      expect(result.errors[:base]).to include I18n.t(:wrong_file_format)
      expect(principal.reload.avatar_type).to be_nil
      expect(principal.avatar_color).to be_nil
      expect(principal.local_avatar_attachment).to be_nil
    end
  end

  it_behaves_like "avatar settings with an image"

  it "rejects the image source when no image exists" do
    result = service.call(attributes: { avatar_type: "image" })

    expect(result).not_to be_success
    expect(result.errors[:base]).to include I18n.t("avatars.image_required")
    expect(principal.reload.avatar_type).to be_nil
  end

  it "changes the cache key of the user when only the source changes" do
    expect { service.call(attributes: { avatar_type: "initials" }) }
      .to change { principal.reload.updated_at }
  end

  context "for a group" do
    let(:user) { create(:admin) }
    let(:principal) { create(:group) }

    it_behaves_like "avatar settings with an image"
  end
end
