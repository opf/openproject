#-- encoding: UTF-8
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

shared_examples_for 'is a countable repository' do
  let(:job) { ::Scm::StorageUpdaterJob.new repository }
  before do
    allow(::Scm::StorageUpdaterJob).to receive(:new).and_return(job)
    allow(job).to receive(:repository).and_return(repository)
  end
  it 'is countable' do
    expect(repository.scm).to be_storage_available
  end

  context 'with patched counter' do
    let(:count) { 1234 }

    before do
      allow(repository.scm).to receive(:count_repository!).and_return(count)
    end

    it 'has has not been counted initially' do
      expect(repository.required_storage_bytes).to be == 0
      expect(repository.storage_updated_at).to be_nil
    end

    it 'counts the repository storage automatically' do
      expect(repository.required_storage_bytes).to be == 0
      expect(repository.required_disk_storage).to be == count
      expect(repository.storage_updated_at).to be >= 1.minute.ago
    end

    context 'when latest count is outdated' do
      before do
        allow(repository).to receive(:storage_updated_at).and_return(24.hours.ago)
      end

      it 'sucessfuly updates the count to what the adapter returns' do
        expect(repository.required_storage_bytes).to be == 0
        expect(repository.required_disk_storage).to be == count
      end
    end
  end

  context 'with real counter' do
    it 'counts the repository storage automatically' do
      expect(repository.required_storage_bytes).to be == 0
      expect(repository.required_disk_storage).to be > 1.kilobyte
      expect(repository.storage_updated_at).to be >= 1.minute.ago
    end
  end
end

shared_examples_for 'is not a countable repository' do
  it 'is not countable' do
    expect(repository.scm).not_to be_storage_available
  end

  it 'does not return or update the count' do
    expect(::Scm::StorageUpdaterJob).not_to receive(:new)
    expect(repository.required_disk_storage).to be_nil
  end
end
