#-- encoding: UTF-8
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

##
# Create a temporary +vendor+ repository from the stored fixture.
# Automatically extracts and destroys said repository,
# however does not provide single example isolation
# due to performance.
# As we do not write to the repository, we don't need this kind
# of isolation.
def with_filesystem_repository(vendor, command = nil, &block)
  repo_dir = File.join(Rails.root, 'tmp', 'test', "#{vendor}_repository")
  fixture = File.join(Rails.root, "spec/fixtures/repositories/#{vendor}_repository.tar.gz")

  before(:all) do
    ['tar', command].compact.each do |cmd|
      begin
        # Avoid `which`, as it's not POSIX
        Open3.capture2e(cmd, '--version')
      rescue Errno::ENOENT
        skip "#{cmd} was not found in PATH. Skipping local repository specs"
      end
    end

    # Create repository
    FileUtils.mkdir_p repo_dir
    system "tar -xzf #{fixture} -C #{repo_dir}"
  end

  after(:all) do
    FileUtils.remove_dir repo_dir
  end

  block.call(repo_dir)
end

def with_subversion_repository(&block)
  with_filesystem_repository('subversion', 'svn', &block)
end

def with_git_repository(&block)
  with_filesystem_repository('git', 'git', &block)
end

##
# Many specs required any repository to be available,
# often Filesystem adapter was used, even though
# no actual filesystem access occurred.
# Instead, we wrap these repository specs in a virtual
# subversion repository which does not exist on disk.
def with_virtual_subversion_repository(&block)
  let(:repository) { FactoryBot.create(:repository_subversion) }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(['subversion'])
  end

  block.call
end
