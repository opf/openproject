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
