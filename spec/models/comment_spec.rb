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

require "spec_helper"

RSpec.describe Comment do
  shared_let(:user) { create(:user) }
  shared_let(:news) { create(:news) }

  let(:commented) { news }

  subject(:comment) { build(:comment, author: user, comments: "some important words", commented:) }

  describe "associations" do
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to belong_to(:commented) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:commented) }
    it { is_expected.to validate_presence_of(:comments) }
  end

  describe "#create" do
    before do
      allow(OpenProject::Notifications).to receive(:send)
    end

    context "for news" do
      it "creates the comment" do
        expect { comment.save! }
          .to change(described_class, :count).by(1).and change { commented.reload.comments_count }.by(1)

        aggregate_failures "sends a news comment added event" do
          expect(OpenProject::Notifications).to have_received(:send)
          .with(OpenProject::Events::NEWS_COMMENT_CREATED,
                comment: comment, send_notification: true)
        end
      end
    end
  end

  describe "#destroy" do
    before { comment.save! }

    it "decrements the comments_count on the commented object" do
      expect { comment.destroy! }.to change { commented.reload.comments_count }.by(-1)
    end
  end

  describe "#texts" do
    it "reads the comments" do
      expect(described_class.new(comments: "some important words").text)
        .to eql "some important words"
    end
  end

  describe "#valid?" do
    it "is valid" do
      expect(comment)
        .to be_valid
    end

    it "is invalid on an empty comments" do
      comment.comments = ""

      expect(comment)
        .not_to be_valid
    end

    it "is invalid without comments" do
      comment.comments = nil

      expect(comment)
        .not_to be_valid
    end

    it "is invalid without author" do
      comment.author = nil

      expect(comment)
        .not_to be_valid
    end
  end
end
