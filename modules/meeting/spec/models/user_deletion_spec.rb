#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe User, '#destroy', type: :model do
  let!(:user) { FactoryBot.create(:user) }
  let!(:user2) { FactoryBot.create(:user) }
  let(:substitute_user) { DeletedUser.first }
  let(:project) do
    FactoryBot.create(:valid_project)
  end

  let(:meeting) do
    FactoryBot.create(:meeting,
                      project: project,
                      author: user2)
  end
  let(:participant) do
    FactoryBot.create(:meeting_participant,
                      user: user,
                      meeting: meeting,
                      invited: true,
                      attended: true)
  end

  shared_examples_for 'updated journalized associated object' do
    before do
      allow(User).to receive(:current).and_return(user2)
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user2)
      end
      associated_instance.save!

      allow(User).to receive(:current).and_return(user) # in order to have the content journal created by the user
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by_id(associated_instance.id)).to eq(associated_instance) }
    it 'should replace the user on all associations' do
      associations.each do |association|
        expect(associated_instance.send(association)).to eq(substitute_user)
      end
    end
    it { expect(associated_instance.journals.first.user).to eq(user2) }
    it 'should update first journal changes' do
      associations.each do |association|
        expect(associated_instance.journals.first.details[(association.to_s + '_id').to_sym].last).to eq(user2.id)
      end
    end
    it { expect(associated_instance.journals.last.user).to eq(substitute_user) }
    it 'should update second journal changes' do
      associations.each do |association|
        expect(associated_instance.journals.last.details[(association.to_s + '_id').to_sym].last).to eq(substitute_user.id)
      end
    end
  end

  shared_examples_for 'created journalized associated object' do
    before do
      allow(User).to receive(:current).and_return(user) # in order to have the content journal created by the user
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user)
      end
      associated_instance.save!

      allow(User).to receive(:current).and_return(user2)
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user2)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by_id(associated_instance.id)).to eq(associated_instance) }
    it 'should keep the current user on all associations' do
      associations.each do |association|
        expect(associated_instance.send(association)).to eq(user2)
      end
    end
    it { expect(associated_instance.journals.first.user).to eq(substitute_user) }
    it 'should update the first journal' do
      associations.each do |association|
        expect(associated_instance.journals.first.details[(association.to_s + '_id').to_sym].last).to eq(substitute_user.id)
      end
    end
    it { expect(associated_instance.journals.last.user).to eq(user2) }
    it 'should update the last journal' do
      associations.each do |association|
        expect(associated_instance.journals.last.details[(association.to_s + '_id').to_sym].first).to eq(substitute_user.id)
        expect(associated_instance.journals.last.details[(association.to_s + '_id').to_sym].last).to eq(user2.id)
      end
    end
  end

  describe 'WHEN the user created a meeting' do
    let(:associations) { [:author] }
    let(:associated_instance) { FactoryBot.build(:meeting, project: project) }
    let(:associated_class) { Meeting }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user updated a meeting' do
    let(:associations) { [:author] }
    let(:associated_instance) { FactoryBot.build(:meeting, project: project) }
    let(:associated_class) { Meeting }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user created a meeting agenda' do
    let(:associations) { [:author] }
    let(:associated_instance) do
      FactoryBot.build(:meeting_agenda, meeting: meeting,
                                         text: 'lorem')
    end
    let(:associated_class) { MeetingAgenda }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user updated a meeting agenda' do
    let(:associations) { [:author] }
    let(:associated_instance) do
      FactoryBot.build(:meeting_agenda, meeting: meeting,
                                         text: 'lorem')
    end
    let(:associated_class) { MeetingAgenda }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user created a meeting minutes' do
    let(:associations) { [:author] }
    let(:associated_instance) do
      FactoryBot.build(:meeting_minutes,
                       meeting: meeting,
                       text: 'lorem')
    end
    let(:associated_class) { MeetingMinutes }

    it_should_behave_like 'created journalized associated object'
  end

  describe 'WHEN the user updated a meeting minutes' do
    let(:associations) { [:author] }
    let(:associated_instance) do
      FactoryBot.build(:meeting_minutes,
                       meeting: meeting,
                       text: 'lorem')
    end
    let(:associated_class) { MeetingMinutes }

    it_should_behave_like 'updated journalized associated object'
  end

  describe 'WHEN the user participated in a meeting' do
    before do
      participant
      # user2 added to participants by beeing the author

      user.destroy
      meeting.reload
      participant.reload
    end

    it { expect(meeting.participants.map(&:user)).to match_array([DeletedUser.first, user2]) }
    it { expect(participant.invited).to be_truthy }
    it { expect(participant.attended).to be_truthy }
  end
end
