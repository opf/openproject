#-- copyright
#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require "spec_helper"

RSpec.describe Comment do
  shared_let(:user) { create(:user) }
  shared_let(:news) { create(:news) }
  let(:comment) { described_class.new(author: user, comments: "some important words", commented: news) }

  describe "#create" do
    it "creates the comment" do
      expect(described_class.create(commented: news, author: user, comments: "some important words"))
        .to be_truthy
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
