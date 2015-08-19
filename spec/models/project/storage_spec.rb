#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe Project::Storage, type: :model do
  let(:project1) { FactoryGirl.create(:project).reload }

  let(:project2) { FactoryGirl.create(:project) }
  let(:repository2) { FactoryGirl.create(:repository_git, project: project2) }

  let(:wp) { FactoryGirl.create(:work_package, project: project1) }
  let(:wikipage) {
    FactoryGirl.create(:wiki_page,
                       wiki: project1.wiki)
  }

  before do
    FactoryGirl.create_list(:attachment, 10, filesize: 250, container: wp)
    FactoryGirl.create(:attachment, filesize: 10000, container: wikipage)

    repository2.update_attributes(required_storage_bytes: 1234)
  end

  describe '#with_required_storage' do
    it 'counts projects correctly' do
      p1, p2 = Project.with_required_storage.find(project1.id, project2.id)

      # The automatically created wiki for a project does not seem to
      # be properly reloaded here in all cases.
      project1.wiki.reload

      expect(p1.work_package_required_space).to eq(2500)
      expect(p1.repositories_required_space).to be_nil

      expect(p1.required_disk_space).to eq(12500)

      expect(p2.wiki_required_space).to be_nil
      expect(p2.work_package_required_space).to be_nil
      expect(p2.repositories_required_space).to eq(1234)

      expect(p2.required_disk_space).to eq(1234)
    end

    it 'outputs the correct total amount' do
      expect(Project.total_projects_size).to eq(13734)
    end

    context 'with a project with all modules' do
      let(:repository1) { FactoryGirl.create(:repository_git, project: project1) }
      before do
        repository1.update_attributes(required_storage_bytes: 543211234)
      end

      it 'counts all projects correctly' do
        project = Project.with_required_storage.find(project1.id)

        expect(project.wiki_required_space).to eq(10000)
        expect(project.work_package_required_space).to eq(2500)
        expect(project.repositories_required_space).to eq(543211234)

        expect(project.required_disk_space).to eq(543223734)
      end

      it 'outputs the correct total amount' do
        expect(Project.total_projects_size).to eq(543224968)
      end
    end
  end

  describe '#count_required_storage' do
    it 'provides a hash of the storage information' do
      storage = project1.count_required_storage

      expect(storage['total']).to eq(12500)
      expect(storage['modules'].length).to eq(2)
      expect(storage['modules']['project_module_wiki']).to eq(10000)
      expect(storage['modules']['label_work_package_plural']).to eq(2500)
    end

    it 'works with partially available information' do
      storage = project2.count_required_storage

      expect(storage['total']).to eq(1234)
      expect(storage['modules'].length).to eq(1)
      expect(storage['modules']['label_repository']).to eq(1234)
    end
  end
end
