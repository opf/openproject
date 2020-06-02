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

require 'spec_helper'

describe Activities::WorkPackageActivityProvider, type: :model do
  let(:event_scope)               { 'work_packages' }
  let(:work_package_edit_event)   { 'work_package-edit' }
  let(:work_package_closed_event) { 'work_package-closed' }

  let(:user) { FactoryBot.create :admin }
  let(:role) { FactoryBot.create :role }
  let(:status_closed) { FactoryBot.create :closed_status }
  let(:work_package) do
    User.execute_as(user) do
      FactoryBot.create :work_package
    end
  end
  let!(:work_packages) { [work_package] }

  describe '.find_events' do
    context 'when a work package has been created' do
      let(:subject) do
        Activities::WorkPackageActivityProvider
          .find_events(event_scope, user, Date.yesterday, Date.tomorrow, {})
      end

      it 'has the edited event type' do
        expect(subject[0].event_type)
          .to eql(work_package_edit_event)
      end

      it 'has an id to the author stored' do
        expect(subject[0].author_id)
          .to eql(user.id)
      end
    end

    context 'should be selected and ordered correctly' do
      let!(:work_packages) { (1..5).map { (FactoryBot.create :work_package, author: user).id.to_s } }

      let(:subject) do
        Activities::WorkPackageActivityProvider
          .find_events(event_scope, user, Date.yesterday, Date.tomorrow, limit: 3)
          .map { |a| a.journable_id.to_s }
      end
      it { is_expected.to eq(work_packages.reverse.first(3)) }
    end

    context 'when a work package has been created and then closed' do
      let(:subject) do
        Activities::WorkPackageActivityProvider
          .find_events(event_scope, user, Date.yesterday, Date.tomorrow, limit: 10)
      end

      before do
        login_as(user)

        work_package.status = status_closed
        work_package.save(validate: false)
      end

      it 'only returns a single event (as it is aggregated)' do
        expect(subject.count)
          .to eql(1)
      end

      it 'has the closed event type' do
        expect(subject[0].event_type)
          .to eql(work_package_closed_event)
      end
    end

    context 'for a non admin user' do
      let(:project) { FactoryBot.create(:project) }
      let(:child_project1) { FactoryBot.create(:project, parent: project) }
      let(:child_project2) { FactoryBot.create(:project, parent: project) }
      let(:child_project3) { FactoryBot.create(:project, parent: project) }
      let(:child_project4) { FactoryBot.create(:project, parent: project, public: true) }

      let(:parent_work_package) { FactoryBot.create(:work_package, project: project) }
      let(:child1_work_package) { FactoryBot.create(:work_package, project: child_project1) }
      let(:child2_work_package) { FactoryBot.create(:work_package, project: child_project2) }
      let(:child3_work_package) { FactoryBot.create(:work_package, project: child_project3) }
      let(:child4_work_package) { FactoryBot.create(:work_package, project: child_project4) }

      let!(:work_packages) do
        [parent_work_package, child1_work_package, child2_work_package, child3_work_package, child4_work_package]
      end

      let(:user) do
        FactoryBot.create(:user).tap do |u|
          FactoryBot.create(:member,
                            user: u,
                            project: project,
                            roles: [FactoryBot.create(:role, permissions: [:view_work_packages])])
          FactoryBot.create(:member,
                            user: u,
                            project: child_project1,
                            roles: [FactoryBot.create(:role, permissions: [:view_work_packages])])
          FactoryBot.create(:member,
                            user: u,
                            project: child_project2,
                            roles: [FactoryBot.create(:role, permissions: [])])

          FactoryBot.create(:non_member, permissions: [:view_work_packages])
        end
      end

      let(:subject) do
        # lft and rgt need to be updated
        project.reload

        Activities::WorkPackageActivityProvider
          .find_events(event_scope, user, Date.yesterday, Date.tomorrow, project: project, with_subprojects: true)
      end

      it 'returns only visible work packages' do
        expect(subject.map(&:journable_id))
          .to match_array([parent_work_package, child1_work_package, child4_work_package].map(&:id))
      end
    end
  end
end
