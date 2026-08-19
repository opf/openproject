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

RSpec.describe EmojiReactions::GroupedQueries do
  shared_let(:project) { create(:project, enabled_internal_comments: true) }
  shared_let(:work_package) { create(:work_package, project:) }

  shared_let(:wp_journal1) { add_journal }
  shared_let(:wp_journal2) { add_journal }
  shared_let(:wp_internal_journal) { add_journal(internal: true) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  let(:thumbs_up_reactions) do
    [user1, user2].each do |user|
      create(:emoji_reaction, reactable: wp_journal1, user: user, reaction: :thumbs_up)
      create(:emoji_reaction, reactable: wp_internal_journal, user: user, reaction: :thumbs_up)
    end
  end

  let(:thumbs_down_reactions) { create(:emoji_reaction, reactable: wp_journal2, user: user2, reaction: :thumbs_down) }

  before do
    thumbs_up_reactions
    thumbs_down_reactions
  end

  describe ".grouped_work_package_journals_emoji_reactions" do
    it "returns grouped emoji reactions for work package journals" do
      result = described_class.grouped_work_package_journals_emoji_reactions(work_package)

      expect(result[0].reaction).to eq("thumbs_up")
      expect(result[0].reactions_count).to eq(2)
      expect(result[0].reacting_users).to eq([[user1.id, user1.name], [user2.id, user2.name]])

      expect(result[1].reaction).to eq("thumbs_down")
      expect(result[1].reactions_count).to eq(1)
      expect(result[1].reacting_users).to eq([[user2.id, user2.name]])
    end

    context "when the current user is allowed to view internal comments", with_ee: [:internal_comments] do
      let(:current_user) do
        create(:user, member_with_permissions: { work_package.project => %i[view_work_packages view_internal_comments] })
      end

      before do
        allow(User).to receive(:current).and_return(current_user)
      end

      it "returns grouped emoji reactions for work package journals" do
        result = described_class.grouped_work_package_journals_emoji_reactions(work_package)

        result[0..1].each do |r|
          expect(r.reaction).to eq("thumbs_up")
          expect(r.reactions_count).to eq(2)
          expect(r.reacting_users).to eq([[user1.id, user1.name], [user2.id, user2.name]])
        end

        expect(result[2].reaction).to eq("thumbs_down")
        expect(result[2].reactions_count).to eq(1)
        expect(result[2].reacting_users).to eq([[user2.id, user2.name]])
      end
    end

    context "when no reactions exist" do
      it "returns an empty hash" do
        work_package = build_stubbed(:work_package)
        result = described_class.grouped_work_package_journals_emoji_reactions(work_package)

        expect(result).to eq([])
      end
    end
  end

  describe ".grouped_work_package_journals_emoji_reactions_by_reactable" do
    it "returns grouped emoji reactions for work package journals" do
      result = described_class.grouped_work_package_journals_emoji_reactions_by_reactable(work_package)

      expect(result.size).to eq(2)

      expect(result).to eq(
        wp_journal1.id => {
          thumbs_up: {
            count: 2,
            users: [{ id: user1.id, name: user1.name }, { id: user2.id, name: user2.name }]
          }
        },
        wp_journal2.id => {
          thumbs_down: {
            count: 1,
            users: [{ id: user2.id, name: user2.name }]
          }
        }
      )
    end

    context "when the current user is allowed to view internal comments", with_ee: [:internal_comments] do
      let(:current_user) do
        create(:user, member_with_permissions: { work_package.project => %i[view_work_packages view_internal_comments] })
      end

      before do
        allow(User).to receive(:current).and_return(current_user)
      end

      it "returns grouped emoji reactions for work package journals" do
        result = described_class.grouped_work_package_journals_emoji_reactions_by_reactable(work_package)

        expect(result.size).to eq(3)

        expect(result).to eq(
          wp_journal1.id => {
            thumbs_up: {
              count: 2,
              users: [{ id: user1.id, name: user1.name }, { id: user2.id, name: user2.name }]
            }
          },
          wp_journal2.id => {
            thumbs_down: {
              count: 1,
              users: [{ id: user2.id, name: user2.name }]
            }
          },
          wp_internal_journal.id => {
            thumbs_up: {
              count: 2,
              users: [{ id: user1.id, name: user1.name }, { id: user2.id, name: user2.name }]
            }
          }
        )
      end
    end

    context "when no reactions exist" do
      it "returns an empty hash" do
        work_package = build_stubbed(:work_package)
        result = described_class.grouped_work_package_journals_emoji_reactions_by_reactable(work_package)

        expect(result).to eq({})
      end
    end
  end

  describe ".grouped_journal_emoji_reactions_by_reactable" do
    context "with a single reactable" do
      it "returns grouped emoji reactions for that journal" do
        result = described_class.grouped_emoji_reactions_by_reactable(reactable: wp_journal1)

        expect(result).to eq(
          wp_journal1.id => {
            thumbs_up: {
              count: 2,
              users: [{ id: user1.id, name: user1.name }, { id: user2.id, name: user2.name }]
            }
          }
        )
      end
    end

    context "with multiple reactions from different users at different times" do
      let(:user3) { create(:user) }

      before do
        create(:emoji_reaction, reactable: wp_journal1, user: user3, reaction: :thumbs_up, created_at: 1.day.ago)
        create(:emoji_reaction, reactable: wp_journal1, user: user3, reaction: :thumbs_down, created_at: 2.days.ago)
      end

      it "groups emoji reactions and users in ascending order" do
        result = described_class.grouped_emoji_reactions_by_reactable(reactable: wp_journal1)

        expect(result).to eq(
          wp_journal1.id => {
            thumbs_down: {
              count: 1,
              users: [{ id: user3.id, name: user3.name }]
            },
            thumbs_up: {
              count: 3,
              users: [
                { id: user3.id, name: user3.name },
                { id: user1.id, name: user1.name },
                { id: user2.id, name: user2.name }
              ]
            }
          }
        )
      end
    end

    context "when no reactable exists in the grouped results" do
      it "returns an empty hash" do
        result = described_class.grouped_emoji_reactions_by_reactable(reactable: wp_journal1)
        non_existent_id = 1234

        expect(result[non_existent_id]).to eq({})
      end
    end
  end

  describe ".grouped_emoji_reactions" do
    it "returns grouped emoji reactions" do
      result = described_class.grouped_emoji_reactions(reactable_id: work_package.journal_ids, reactable_type: "Journal")

      result[0..1].each do |r|
        expect(r.reaction).to eq("thumbs_up")
        expect(r.reactions_count).to eq(2)
        expect(r.reacting_users).to eq([[user1.id, user1.name], [user2.id, user2.name]])
      end

      expect(result[2].reaction).to eq("thumbs_down")
      expect(result[2].reactions_count).to eq(1)
      expect(result[2].reacting_users).to eq([[user2.id, user2.name]])
    end

    context "when user format is set to :username", with_settings: { user_format: :username } do
      it "returns grouped emoji reactions with usernames" do
        result = described_class.grouped_emoji_reactions(reactable_id: work_package.journal_ids, reactable_type: "Journal")

        expect(result[0].reacting_users).to eq([[user1.id, user1.login], [user2.id, user2.login]])
      end
    end

    context "when user format is set to :firstname", with_settings: { user_format: :firstname } do
      it "returns grouped emoji reactions with first and last names" do
        result = described_class.grouped_emoji_reactions(reactable: wp_journal2)

        expect(result[0].reacting_users).to eq([[user2.id, user2.firstname]])
      end
    end

    context "when user format is set to :lastname_comma_firstname", with_settings: { user_format: :lastname_comma_firstname } do
      it "returns grouped emoji reactions with last coma firstname" do
        result = described_class.grouped_emoji_reactions(reactable: wp_journal1)

        expect(result[0].reacting_users).to eq(
          [
            [user1.id, "#{user1.lastname}, #{user1.firstname}"],
            [user2.id, "#{user2.lastname}, #{user2.firstname}"]
          ]
        )
      end
    end

    context "when user format is set to :lastname_n_firstname", with_settings: { user_format: :lastname_n_firstname } do
      it "returns grouped emoji reactions with last firstname" do
        result = described_class.grouped_emoji_reactions(reactable: wp_journal1)

        expect(result[0].reacting_users).to eq(
          [
            [user1.id, "#{user1.lastname}#{user1.firstname}"],
            [user2.id, "#{user2.lastname}#{user2.firstname}"]
          ]
        )
      end
    end
  end

  def add_journal(notes: "This is a test note", internal: false)
    work_package.add_journal(user: work_package.author, notes:, internal:)
    work_package.save(validate: false)
    work_package.journals.last
  end
end
