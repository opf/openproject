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

RSpec.describe Token::ICal do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:query) { create(:query, project:) }
  let(:name) { "unique_name" }

  it "inherits from Token::HashedToken" do
    expect(described_class).to be < Token::HashedToken
  end

  describe "in contrast to HashedToken" do
    it "needs to be assigned to a query with a name" do
      # ical tokens are only valid for a specific query (scoped to a query)
      # thus an ical_token cannot be created without such an assignment
      ical_token1 = described_class.create(user:)

      expect(ical_token1.errors[:ical_token_query_assignment].first).to eq("must exist")
      expect(described_class.where(user_id: user.id)).to be_empty

      # ical tokens need to have a name
      # thus an ical_token cannot be created without a name although a query is given
      ical_token2 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query: }
      )

      expect(ical_token2.errors["ical_token_query_assignment.name"].first).to eq("is mandatory. Please select a name.")
      expect(described_class.where(user_id: user.id)).to be_empty

      # if a query and name is given, the token can be created
      ical_token3 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query:, name: }
      )
      expect(ical_token3.errors).to be_empty
      expect(ical_token3.query).to eq query
      expect(ical_token3.ical_token_query_assignment.name).to eq name
      expect(described_class.where(user_id: user.id)).to contain_exactly(
        ical_token3
      )
    end

    it "a user can have N ical tokens per query with different names" do
      # Every time an ical url is generated, a new ical token will be generated for this url as well
      # the existing ical tokens (and thus urls) should still be valid
      # until the user decides to revert all existing ical tokens of a query
      # therefore a user needs to be allowed to have N ical tokens per query
      ical_token1 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query:, name: "#{name}_1" }
      )
      ical_token2 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query:, name: "#{name}_2" }
      )

      expect(described_class.where(user_id: user.id)).to contain_exactly(
        ical_token1, ical_token2
      )

      query2 = create(:query, project:)

      ical_token3 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query: query2, name: "#{name}_3" }
      )
      ical_token4 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query: query2, name: "#{name}_4" }
      )

      expect(described_class.where(user_id: user.id)).to contain_exactly(
        ical_token1, ical_token2, ical_token3, ical_token4
      )
    end

    it "a user cannot have N ical tokens per query with the same name" do
      ical_token1 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query:, name: "#{name}_1" }
      )
      ical_token2 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query:, name: "#{name}_1" }
      )

      expect(ical_token2.errors["ical_token_query_assignment.name"].first).to eq(
        "is already in use. Please select another name."
      )

      expect(described_class.where(user_id: user.id)).to contain_exactly(
        ical_token1
      )

      # name can be used for another query though:

      query2 = create(:query, project:)

      ical_token3 = described_class.create(
        user:,
        ical_token_query_assignment_attributes: { query: query2, name: "#{name}_1" }
      )

      expect(described_class.where(user_id: user.id)).to contain_exactly(
        ical_token1, ical_token3
      )
    end

    describe "#create_and_return_value method" do
      it "expects the query and token name and returns a token value" do
        ical_token1_value = nil

        expect do
          ical_token1_value = described_class.create_and_return_value(
            user,
            query,
            name
          )
        end.to change { described_class.where(user_id: user.id).count }.by(1)

        ical_token1 = described_class.where(user_id: user.id).last

        # rubocop:disable Rails/DynamicFindBy
        expect(described_class.find_by_plaintext_value(ical_token1_value)).to eq ical_token1
        # rubocop:enable Rails/DynamicFindBy

        expect(ical_token1.query).to eq query
        expect(ical_token1.ical_token_query_assignment.name).to eq name
      end

      it "does not return a token value if token was not successfully persisted" do
        ical_token1_value = nil
        ical_token2_value = nil

        expect do
          ical_token1_value = described_class.create_and_return_value(
            user,
            query,
            name
          )
          # same name cannot be used twice for the same query and user
          expect do
            ical_token2_value = described_class.create_and_return_value(
              user,
              query,
              name
            )
          end.to raise_error(ActiveRecord::RecordInvalid)
        end.to change { described_class.where(user_id: user.id).count }.by(1)

        expect(ical_token1_value).to be_present
        expect(ical_token2_value).to be_nil

        ical_token1 = described_class.where(user_id: user.id).last

        # rubocop:disable Rails/DynamicFindBy
        expect(described_class.find_by_plaintext_value(ical_token1_value)).to eq ical_token1
        # rubocop:enable Rails/DynamicFindBy
      end
    end

    describe "dependent destroyed" do
      context "when associated query is destroyed" do
        it "the ical_token is destroyed as well" do
          described_class.create(
            user:,
            ical_token_query_assignment_attributes: { query:, name: }
          )
          expect do
            query.destroy!
          end.to change(described_class, :count).by(-1)

          expect(described_class.all).to be_empty
          expect(ICalTokenQueryAssignment.all).to be_empty
        end
      end

      context "when associated user is destroyed" do
        it "the ical_token is destroyed as well" do
          described_class.create(
            user:,
            ical_token_query_assignment_attributes: { query:, name: }
          )
          expect do
            user.destroy!
          end.to change(described_class, :count).by(-1)

          expect(described_class.all).to be_empty
          expect(ICalTokenQueryAssignment.all).to be_empty
        end
      end

      context "when ical_token is destroyed" do
        it "the ical_token_query_assignment is destroyed as well" do
          ical_token = described_class.create(
            user:,
            ical_token_query_assignment_attributes: { query:, name: }
          )
          expect do
            ical_token.destroy!
          end.to change(ICalTokenQueryAssignment, :count).by(-1)

          expect(ICalTokenQueryAssignment.all).to be_empty
        end
      end
    end
  end

  describe "behaves like Token::HashedToken if created with query assignment" do
    subject do
      described_class.new(
        user:,
        ical_token_query_assignment_attributes: { query:, name: }
      )
    end

    # TODO: following code is copy pasted from hashed_token_spec
    # in order to make sure the token behaves in the same way in it's basics
    # cheching for inheritance does not safely check if the basic behaviour is the same
    # is there a better way of reusing the specs from hashed_token_spec?
    describe "token value" do
      it "is generated on a new instance" do
        expect(subject.value).to be_present
      end

      it "provides the generated plain value on a new instance" do
        expect(subject.valid_plaintext?(subject.plain_value)).to be true
      end

      it "hashes the plain value to value" do
        expect(subject.value).not_to eq(subject.plain_value)
      end

      it "does not keep the value when finding it" do
        subject.save!

        instance = described_class.where(user:).last
        expect(instance.plain_value).to be_nil
      end
    end

    describe "#find_by_plaintext_value" do
      before do
        subject.save!
      end

      it "finds using the plaintext value" do
        # rubocop:disable Rails/DynamicFindBy
        expect(described_class.find_by_plaintext_value(subject.plain_value)).to eq subject
        expect(described_class.find_by_plaintext_value("foobar")).to be_nil
        # rubocop:enable Rails/DynamicFindBy
      end
    end
  end
end
