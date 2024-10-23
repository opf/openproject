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

RSpec.describe Reactable do
  shared_let(:work_package) { create(:work_package) }

  let(:wp_journal1) { create(:work_package_journal, journable: work_package, version: 2) }
  let(:wp_journal2) { create(:work_package_journal, journable: work_package, version: 3) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  let(:thumbs_up_reactions) do
    [user1, user2].each do |user|
      create(:emoji_reaction, reactable: wp_journal1, user: user, reaction: :thumbs_up)
    end
  end

  let(:thumbs_down_reactions) { create(:emoji_reaction, reactable: wp_journal2, user: user2, reaction: :thumbs_down) }

  describe "Associations" do
    it { expect(wp_journal1).to have_many(:emoji_reactions) }
  end

  describe ".grouped_work_package_journals_emoji_reactions" do
    before do
      thumbs_up_reactions
      thumbs_down_reactions
    end

    it "returns grouped emoji reactions" do
      result = Journal.grouped_work_package_journals_emoji_reactions(work_package)

      expect(result.size).to eq({ "thumbs_up" => 2, "thumbs_down" => 1 })

      expect(result[0].reaction).to eq("thumbs_up")
      expect(result[0].count).to eq(2)
      expect(result[0].user_details).to eq([[user1.id, user1.name], [user2.id, user2.name]])

      expect(result[1].reaction).to eq("thumbs_down")
      expect(result[1].count).to eq(1)
      expect(result[1].user_details).to eq([[user2.id, user2.name]])
    end

    context "when user format is set to :username", with_settings: { user_format: :username } do
      it "returns grouped emoji reactions with usernames" do
        result = Journal.grouped_work_package_journals_emoji_reactions(work_package)

        expect(result[0].user_details).to eq([[user1.id, user1.login], [user2.id, user2.login]])
      end
    end

    context "when user format is set to :firstname", with_settings: { user_format: :firstname } do
      it "returns grouped emoji reactions with first and last names" do
        result = Journal.grouped_work_package_journals_emoji_reactions(work_package)

        expect(result[0].user_details).to eq(
          [
            [user1.id, user1.firstname],
            [user2.id, user2.firstname]
          ]
        )
      end
    end

    context "when user format is set to :lastname_coma_firstname", with_settings: { user_format: :lastname_coma_firstname } do
      it "returns grouped emoji reactions with last coma firstname" do
        result = Journal.grouped_work_package_journals_emoji_reactions(work_package)

        expect(result[0].user_details).to eq(
          [
            [user1.id, "#{user1.lastname}, #{user1.firstname}"],
            [user2.id, "#{user2.lastname}, #{user2.firstname}"]
          ]
        )
      end
    end

    context "when user format is set to :lastname_n_firstname", with_settings: { user_format: :lastname_n_firstname } do
      it "returns grouped emoji reactions with last firstname" do
        result = Journal.grouped_work_package_journals_emoji_reactions(work_package)

        expect(result[0].user_details).to eq(
          [
            [user1.id, "#{user1.lastname}#{user1.firstname}"],
            [user2.id, "#{user2.lastname}#{user2.firstname}"]
          ]
        )
      end
    end
  end
end
