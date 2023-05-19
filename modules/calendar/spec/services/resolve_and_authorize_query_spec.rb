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

describe Calendar::ResolveAndAuthorizeQueryService, type: :model do
  let(:sufficient_permissions) { %i[view_work_packages share_calendars] }
  let(:insufficient_permissions) { %i[view_work_packages] }
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: sufficient_permissions)
  end
  let(:query1) do
    create(:query,
           project:,
           user: user,
           public: false) # privat query
  end
  let(:query2) do
    create(:query,
           project:,
           user: user,
           public: true) # public query
  end
  let(:ical_token_instance_for_query1) do
    Token::ICal.create(user: user, 
      ical_token_query_assignment_attributes: { query: query1, name: "My Token", user_id: user.id }
    )
  end
  let(:ical_token_instance_for_query2) do
    Token::ICal.create(user: user, 
      ical_token_query_assignment_attributes: { query: query2, name: "My Token", user_id: user.id }
    )
  end

  let(:instance) do
    described_class.new
  end

  shared_examples 'not found' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'if user is authenticated to read from query and user is permitted to use ical sharing' do
    context 'if ical token belongs to query' do
      context 'if user owns the query which is private' do
        subject do 
          instance.call(
            query_id: query1.id, 
            ical_token_instance: ical_token_instance_for_query1
          ) 
        end

        it 'returns the query as result' do
          expect(subject.result)
            .to eq query1
        end

        it 'is a success' do
          expect(subject)
            .to be_success
        end
      end

      context 'if user owns the query which is public' do
        subject do 
          instance.call(
            query_id: query2.id, 
            ical_token_instance: ical_token_instance_for_query2
          ) 
        end

        it 'returns the query as result' do
          expect(subject.result)
            .to eq query2
        end

        it 'is a success' do
          expect(subject)
            .to be_success
        end
      end
    end

    context 'if ical token does NOT belong to query' do
      context 'if user owns the query which is private' do
        subject do 
          instance.call(
            query_id: query1.id, 
            ical_token_instance: ical_token_instance_for_query2
          ) 
        end

        it_behaves_like "not found"
      end

      context 'if user owns the query which is public' do
        subject do 
          instance.call(
            query_id: query2.id, 
            ical_token_instance: ical_token_instance_for_query1
          ) 
        end

        it_behaves_like "not found"
      end
    end

    context 'if ical token is nil' do
      context 'if query is private' do
        subject do 
          instance.call(
            query_id: query1.id, 
            ical_token_instance: nil
          ) 
        end

        it_behaves_like "not found"
      end

      context 'if query is public' do
        subject do 
          instance.call(
            query_id: query2.id, 
            ical_token_instance: nil
          ) 
        end

        it_behaves_like "not found"
      end
    end
  end

  context 'if user is authenticated to read from query but is NOT permitted to use ical sharing' do
    let(:user) do
      create(:user,
        member_in_project: project,
        member_with_permissions: insufficient_permissions)
    end

    context 'if ical token belongs to query' do
      context 'if user owns the query which is private' do
        subject do 
          instance.call(
            query_id: query1.id, 
            ical_token_instance: ical_token_instance_for_query1
          ) 
        end

        it_behaves_like "not found"
      end

      context 'if user owns the query which is public' do
        subject do 
          instance.call(
            query_id: query2.id, 
            ical_token_instance: ical_token_instance_for_query2
          ) 
        end

        it_behaves_like "not found"
      end
    end

    context 'if ical token does NOT belong to query' do
      context 'if user owns the query which is private' do
        subject do 
          instance.call(
            query_id: query1.id, 
            ical_token_instance: ical_token_instance_for_query2
          ) 
        end

        it_behaves_like "not found"
      end

      context 'if user owns the query which is public' do
        subject do 
          instance.call(
            query_id: query2.id, 
            ical_token_instance: ical_token_instance_for_query1
          ) 
        end

        it_behaves_like "not found"
      end
    end
  end

  context 'if user does not own the query' do
    let(:user1) do
      create(:user,
              member_in_project: project,
              member_with_permissions: sufficient_permissions)
    end
    let(:user2) do
      create(:user,
              member_in_project: project,
              member_with_permissions: sufficient_permissions)
    end
    let(:private_query1_of_user1) do
      create(:query,
             project:,
             user: user1,
             public: false)
    end
    let(:public_query2_of_user1) do
      create(:query,
             project:,
             user: user1,
             public: true)
    end
    let(:ical_token_instance_of_user_2_for_query1) do 
      Token::ICal.create(user: user2, 
        ical_token_query_assignment_attributes: { 
          query: private_query1_of_user1, name: "My Token", user_id: user2.id 
        }
      ) 
    end
    let(:ical_token_instance_of_user_2_for_query2) do 
      Token::ICal.create(user: user2, 
        ical_token_query_assignment_attributes: { 
          query: public_query2_of_user1, name: "My Token", user_id: user2.id 
        }
      ) 
    end

    context 'if query is private' do
      subject do 
        instance.call(
          query_id: private_query1_of_user1.id, 
          ical_token_instance: ical_token_instance_of_user_2_for_query1
        ) 
      end

      it_behaves_like "not found"
    end

    context 'if query is public' do
      subject do 
        instance.call(
          query_id: public_query2_of_user1.id, 
          ical_token_instance: ical_token_instance_of_user_2_for_query2
        ) 
      end

      it 'returns the query as result' do
        expect(subject.result)
          .to eq public_query2_of_user1
      end

      it 'is a success' do
        expect(subject)
          .to be_success
      end
    end
  end

  context 'if user is not member of the project (anymore)' do
    let(:project2) { create(:project) }
    let(:user) do
      create(:user,
             member_in_project: project2,
             member_with_permissions: sufficient_permissions)
    end

    # queries (privat and public) owned by user
    # but user is not part of the project anymore

    context 'if query is private' do
      subject do 
        instance.call(
          query_id: query1.id, 
          ical_token_instance: ical_token_instance_for_query1
        ) 
      end

      it_behaves_like "not found"
    end

    context 'if query is public' do
      subject do 
        instance.call(
          query_id: query2.id, 
          ical_token_instance: ical_token_instance_for_query2
        ) 
      end

      it_behaves_like "not found"
    end
  end

  context 'if query id is invalid or nil' do
    context 'if query id is invalid' do
      subject do 
        instance.call(
          query_id: SecureRandom.hex, 
          ical_token_instance: ical_token_instance_for_query1
        ) 
      end

      it_behaves_like "not found"
    end

    context 'if query id is nil' do
      subject do 
        instance.call(
          query_id: nil, 
          ical_token_instance: ical_token_instance_for_query1
        ) 
      end

      it_behaves_like "not found"
    end
  end
end
