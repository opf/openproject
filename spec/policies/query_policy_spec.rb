#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../spec_helper', __FILE__)

describe QueryPolicy, type: :controller do
  let(:user)    { FactoryGirl.build_stubbed(:user) }
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:query)   { FactoryGirl.build_stubbed(:query, project: project) }

  describe :allowed? do
    let(:subject) { described_class.new(user) }

    before do
      allow(user).to receive(:allowed_to?).and_return false
    end

    it 'is false for update if the user has no permission in the project' do
      expect(subject.allowed?(query, :update)).to be_falsy
    end

    it 'is false for update if the user has the save_query permission in the project ' +
       'AND the query is not persisted' do
      allow(user).to receive(:allowed_to?).with(:save_queries, project)
                                          .and_return true
      allow(query).to receive(:persisted?).and_return false

      expect(subject.allowed?(query, :update)).to be_falsy
    end

    it 'is true for update if the user has the save_query permission in the project ' +
       'AND it is his query' do
      allow(user).to receive(:allowed_to?).with(:save_queries, project)
                                          .and_return true
      query.user = user

      expect(subject.allowed?(query, :update)).to be_truthy
    end

    it 'is false for update if the user has the save_query permission in the project ' +
       'AND it is not his query' do
      allow(user).to receive(:allowed_to?).with(:save_queries, project)
                                          .and_return true

      query.user = FactoryGirl.build_stubbed(:user)

      expect(subject.allowed?(query, :update)).to be_falsy
    end

    it 'is false for update if the user lacks the save_query permission in the project ' +
       'AND it is his query' do
      allow(user).to receive(:allowed_to?).with(:save_queries, project)
                                          .and_return false

      query.user = user

      expect(subject.allowed?(query, :update)).to be_falsy
    end

    it 'is true for update if the user has the manage_public_query permission in the project' +
       'AND it is anothers query ' +
       'AND the query is public' do
      allow(user).to receive(:allowed_to?).with(:manage_public_queries, project)
                                          .and_return true
      query.user = FactoryGirl.build_stubbed(:user)
      query.is_public = true

      expect(subject.allowed?(query, :update)).to be_truthy
    end

    it 'is false for update if the user lacks the manage_public_query permission in the project ' +
       'AND it is anothers query ' +
       'AND the query is public' do
      allow(user).to receive(:allowed_to?).with(:manage_public_queries, project)
                                          .and_return false
      query.user = FactoryGirl.build_stubbed(:user)
      query.is_public = true

      expect(subject.allowed?(query, :update)).to be_falsy
    end

    it 'is false for update if the user has the manage_public_query permission in the project ' +
       'AND it is anothers query ' +
       'AND the query is not public' do
      allow(user).to receive(:allowed_to?).with(:manage_public_queries, project)
                                          .and_return true
      query.user = FactoryGirl.build_stubbed(:user)
      query.is_public = false

      expect(subject.allowed?(query, :update)).to be_falsy
    end
  end
end
