#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Watcher, type: :model do
  let(:project) { watchable.project }
  let(:user) { FactoryGirl.build :user, admin: true }
  let(:watcher) do
    FactoryGirl.build :watcher,
                      watchable: watchable,
                      user: user
  end
  let(:watchable) { FactoryGirl.build :work_package }
  let(:other_watcher) do
    FactoryGirl.build :watcher,
                      watchable: watchable,
                      user: other_user
  end
  let(:other_project) { FactoryGirl.create(:project) }
  let(:other_user) { FactoryGirl.create(:user, admin: true) }

  describe '#valid' do
    it 'is valid for an active user' do
      expect(watcher).to be_valid
    end

    it 'is valid for an invited user' do
      user.status = Principal::STATUSES[:invited]
      expect(watcher).to be_valid
    end

    it 'is valid for a registered user' do
      user.status = Principal::STATUSES[:registered]
      expect(watcher).to be_valid
    end
  end

  describe '.prune' do
    shared_examples_for 'a pruned watchable' do
      before do
        watcher.save!
        other_watcher.save!
        user.update_attribute(:admin, false)
        user.reload
      end

      context 'with a matching user scope' do
        it 'removes the watcher' do
          Watcher.prune(user: user)

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune(user: user)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'without a scope' do
        it 'removes the watcher' do
          Watcher.prune

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a non matching user scope' do
        let(:other_other_user) { FactoryGirl.create(:user) }

        it 'leaves the watcher' do
          Watcher.prune(user: other_other_user)

          expect(Watcher.find_by(id: watcher.id)).to eql watcher
        end

        it 'leaves the other watcher' do
          Watcher.prune(user: other_other_user)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a matching user and project_id scope' do
        it 'removes the watcher' do
          Watcher.prune(user: user, project_id: project.id)

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune(user: user, project_id: project.id)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a matching project_id scope' do
        it 'removes the watcher' do
          Watcher.prune(project_id: project.id)

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune(project_id: project.id)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a non matching project_id scope' do
        it 'leaves the watcher' do
          Watcher.prune(project_id: other_project.id)

          expect(Watcher.find_by(id: watcher.id)).to eql watcher
        end

        it 'leaves the other watcher' do
          Watcher.prune(project_id: other_project.id)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end
    end

    shared_examples_for 'no watcher exists' do
      before do
        watchable.save!
      end

      it 'is robust' do
        expect { Watcher.prune }.to_not raise_error
      end
    end

    context 'for a work package' do
      it_behaves_like 'a pruned watchable'
      it_behaves_like 'no watcher exists'
    end

    context 'for a message' do
      let(:board) { FactoryGirl.build(:board) }
      let(:watchable) do
        board.save!
        FactoryGirl.build(:message, board: board)
      end
      let(:project) { board.project }

      it_behaves_like 'a pruned watchable'
      it_behaves_like 'no watcher exists'
    end
  end
end
