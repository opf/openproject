#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe Token::Ical do
  let(:user) { build(:user) }

  subject { described_class.new user: }

  describe 'behaves like Token::HashedToken' do
    it 'inherits from Token::HashedToken' do
      expect(described_class).to be < Token::HashedToken
    end

    # following code is copy pasted from hashed_token_spec
    # in order to make sure the token behaves in the same way in it's basics
    # cheching for inheritance does not safely check if the basic behaviour is the same
    # is there a better way of reusing the specs from hashed_token_spec?
    describe 'token value' do
      it 'is generated on a new instance' do
        expect(subject.value).to be_present
      end

      it 'provides the generated plain value on a new instance' do
        expect(subject.valid_plaintext?(subject.plain_value)).to be true
      end

      it 'hashes the plain value to value' do
        expect(subject.value).not_to eq(subject.plain_value)
      end

      it 'does not keep the value when finding it' do
        subject.save!

        instance = described_class.where(user:).last
        expect(instance.plain_value).to be_nil
      end
    end

    describe '#find_by_plaintext_value' do
      before do
        subject.save!
      end

      it 'finds using the plaintext value' do
        # rubocop:disable Rails/DynamicFindBy
        expect(described_class.find_by_plaintext_value(subject.plain_value)).to eq subject
        expect(described_class.find_by_plaintext_value('foobar')).to be_nil
        # rubocop:enable Rails/DynamicFindBy
      end
    end
  end

  describe 'in contrast to HashedToken' do
    it 'a user can have N ical tokens' do
      # Every time an ical url is generated, a new ical token will be generated for this url as well
      # the existing ical tokens (and thus urls) should still be valid
      # until the user decides to revert all existing ical tokens (and urls)
      # therefore a user needs to be allowed to have N ical token
      ical_token1 = described_class.create(user:)
      ical_token2 = described_class.create(user:)

      expect(described_class.where(user_id: user.id)).to contain_exactly(
        ical_token1, ical_token2
      )
    end
  end
end
