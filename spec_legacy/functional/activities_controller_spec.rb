#-- encoding: UTF-8

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

require_relative '../legacy_spec_helper'

describe ActivitiesController, type: :controller do
  fixtures :all

  render_views

  it 'project index' do
    Journal.delete_all
    public_project = FactoryGirl.create :public_project
    issue = FactoryGirl.create :work_package,
                               project: public_project,
                               status_id: 2,
                               priority_id: 4,
                               author_id: 2,
                               start_date: 1.day.ago.to_date.to_s(:db),
                               due_date: 10.day.from_now.to_date.to_s(:db)

    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               project_id: issue.project_id,
                                               status_id: 1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       notes: 'Some notes with Redmine links: #2, r2.',
                       created_at: 1.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               subject: issue.subject,
                                               status_id: 2,
                                               type_id: issue.type_id,
                                               project_id: issue.project_id)

    get :index, params: { id: 1, with_subprojects: 0 }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:events_by_day)

    assert_select 'h3',
                  content: /#{1.day.ago.to_date.day}/,
                  sibling: {
                    tag: 'dl',
                    child: {
                      tag: 'dt',
                      attributes: { class: /work_package/ },
                      child: {
                        tag: 'a',
                        content: /#{ERB::Util.h(Status.find(2).name)}/
                      }
                    }
                  }
  end

  it 'previous project index' do
    issue = WorkPackage.find(1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               subject: issue.subject,
                                               status_id: issue.status_id,
                                               type_id: issue.type_id,
                                               project_id: issue.project_id)

    get :index, params: { id: 1, from: 3.days.ago.to_date }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:events_by_day)

    assert_select 'h3',
                  content: /#{3.day.ago.to_date.day}/,
                  sibling: {
                    tag: 'dl',
                    child: {
                      tag: 'dt',
                      attributes: { class: /work_package/ },
                      child: {
                        tag: 'a',
                        content: /#{ERB::Util.h(issue.subject)}/
                      }
                    }
                  }
  end

  it 'user index' do
    issue = WorkPackage.find(1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       user_id: 2,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               subject: issue.subject,
                                               status_id: issue.status_id,
                                               type_id: issue.type_id,
                                               project_id: issue.project_id)

    get :index, params: { user_id: 2 }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:events_by_day)

    assert_select 'h3',
                  content: /#{3.day.ago.to_date.day}/,
                  sibling: {
                    tag: 'dl',
                    child: {
                      tag: 'dt',
                      attributes: { class: /work_package/ },
                      child: {
                        tag: 'a',
                        content: /#{ERB::Util.h(WorkPackage.find(1).subject)}/
                      }
                    }
                  }
  end
end
