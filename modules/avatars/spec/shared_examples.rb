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

RSpec.shared_examples_for "an action checked for required login" do
  describe "WITH no login required" do
    before do
      allow(Setting).to receive(:login_required?).and_return(false)
      action
    end

    it "is success" do
      expect(response).to be_successful
    end
  end

  describe "WITH login required" do
    before do
      allow(Setting).to receive(:login_required?).and_return(true)
      action
    end

    it "redirects to the login page" do
      expect(response).to redirect_to signin_path(back_url: redirect_path)
    end
  end
end

RSpec.shared_examples_for "an action requiring login" do
  let(:current) { create(:user) }

  before do
    allow(User).to receive(:current).and_return(current)
  end

  describe "without being logged in" do
    before do
      allow(User).to receive(:current).and_return AnonymousUser.first

      action
    end

    it { expect(response).to redirect_to signin_path(back_url: redirect_path) }
  end

  describe "with being logged in" do
    before do
      action
    end

    it { expect(response).to be_success }
  end
end

RSpec.shared_examples_for "an action requiring admin" do
  let(:current) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(current)
  end

  describe "without being logged in" do
    before do
      allow(User).to receive(:current).and_return AnonymousUser.first

      action
    end

    it { expect(response).to redirect_to signin_path(back_url: redirect_path) }
  end

  describe "with being logged in as a normal user" do
    before do
      allow(User).to receive(:current).and_return create(:user)

      action
    end

    it { expect(response.response_code).to eq(403) }
  end

  describe "with being logged in as admin" do
    before do
      action
    end

    it do
      if respond_to? :successful_response
        successful_response
      else
        expect(response).to be_success
      end
    end
  end
end

RSpec.shared_context "there are users with and without avatars" do
  let(:base_path) { File.expand_path "fixtures", __dir__ }
  let(:user_without_avatar) { create(:user) }
  let(:user_with_avatar) do
    u = create(:user)
    u.attachments = [build(:avatar_attachment, author: u)]
    u
  end
  let(:avatar_file) do
    file = File.new(File.join(base_path, "valid.jpg"), "r")
    testfile = Rack::Test::UploadedFile.new(file.path, "valid.jpg")
    allow(testfile).to receive(:tempfile).and_return(file)
    testfile
  end
  let(:large_avatar_file) do
    file = File.new(File.join(base_path, "too_big.jpg"), "r")
    testfile = Rack::Test::UploadedFile.new(file.path, "too_big.jpg")
    allow(testfile).to receive(:tempfile).and_return(file)
    testfile
  end

  let(:bogus_avatar_file) do
    file = File.new(File.join(base_path, "invalid.jpg"), "r")
    testfile = Rack::Test::UploadedFile.new(file.path, "invalid.jpg")
    allow(testfile).to receive(:tempfile).and_return(file)
    testfile
  end
end

RSpec.shared_examples_for "an action with an invalid user" do
  it do
    do_action
    expect(response).not_to be_success
    expect(response.code).to eq("404")
  end
end

RSpec.shared_context "an action with stubbed User.find" do
  before do
    allow(user).to receive(:save).and_return true if user
    allow(User).to receive(:find) { |id, _args| id.to_s == "0" ? nil : user }
  end
end

RSpec.shared_examples_for "an action that deletes the user's avatar" do
  it do
    expect_any_instance_of(Attachment).to receive(:destroy).and_call_original
    do_action
  end
end
