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

describe Projects::Storage, type: :model do
  let(:project1) {
    FactoryBot.create(:project)
      .reload # Reload required for wiki association to be available
  }
  let(:project2) { FactoryBot.create(:project) }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(['git'])

    wp = FactoryBot.create(:work_package, project: project1)
    FactoryBot.create(:work_package, project: project1)
    FactoryBot.create_list(:attachment, 10, filesize: 250, container: wp)

    wikipage = FactoryBot.create(:wiki_page, wiki: project1.wiki)
    FactoryBot.create(:attachment, filesize: 10000, container: wikipage)

    repo = FactoryBot.create(:repository_git, project: project2)
    repo.update(required_storage_bytes: 1234)
  end

  describe '#with_required_storage' do
    it 'counts projects correctly' do

      # TODO Using storage.find(project1.id) here causes work_package_required_space
      # to be nil or "2500" (Postgres only) occasionally with no definitive solution found.
      # The returned "2500" were pre-Rails4 behavior, thus this might be a Rails bug.
      # Please test with 4.1/4.2
      storage = Project.with_required_storage
      p1 = storage.where(id: project1.id).first
      p2 = storage.where(id: project2.id).first

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
      let(:repository1) { FactoryBot.create(:repository_git, project: project1) }
      before do
        repository1.update(required_storage_bytes: 543211234)
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
