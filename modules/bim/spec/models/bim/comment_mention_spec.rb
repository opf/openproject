# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::CommentMention, type: :model do
  let(:user) { create(:user) }
  let(:comment) { create(:bcf_comment) }
  let(:mention) { create(:bim_comment_mention, user: user, comment: comment) }

  describe 'associations' do
    it { is_expected.to belong_to(:comment) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:bim_comment_mention) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:comment) }

    it 'validates uniqueness of user_id scoped to comment_id' do
      existing = create(:bim_comment_mention)
      duplicate = build(:bim_comment_mention,
                        comment: existing.comment,
                        user: existing.user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:comment_id]).to be_present
    end
  end

  describe 'scopes' do
    let!(:mention1) { create(:bim_comment_mention, user: user) }
    let!(:mention2) { create(:bim_comment_mention) }

    describe '.for_user' do
      it 'returns mentions for specified user' do
        expect(described_class.for_user(user.id)).to include(mention1)
        expect(described_class.for_user(user.id)).not_to include(mention2)
      end
    end

    describe '.for_comment' do
      it 'returns mentions for specified comment' do
        expect(described_class.for_comment(mention1.comment_id)).to include(mention1)
        expect(described_class.for_comment(mention1.comment_id)).not_to include(mention2)
      end
    end

    describe '.recent' do
      it 'orders mentions by created_at descending' do
        mention1.update(created_at: 2.days.ago)
        mention2.update(created_at: 1.day.ago)

        expect(described_class.recent).to eq([mention2, mention1])
      end
    end
  end

  describe '.mentioned_comments_for_user' do
    it 'returns comments where user was mentioned' do
      mentioned_comment = mention.comment

      comments = described_class.mentioned_comments_for_user(user)
      expect(comments).to include(mentioned_comment)
    end
  end

  describe '.mentioned_users_in_comment' do
    let!(:mention2) { create(:bim_comment_mention, comment: comment) }

    it 'returns all users mentioned in a comment' do
      users = described_class.mentioned_users_in_comment(comment)

      expect(users).to include(user)
      expect(users).to include(mention2.user)
    end
  end
end
