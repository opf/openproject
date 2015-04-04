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

require 'legacy_spec_helper'

describe Redmine::Scm::Adapters::FilesystemAdapter, type: :model do
  let(:fs_repository_path) { Rails.root.to_s.gsub(%r{config\/\.\.}, '') + '/tmp/test/filesystem_repository' }

  before do
    skip 'Filesystem test repository NOT FOUND. Skipping unit tests !!! See doc/RUNNING_TESTS.' unless File.directory?(fs_repository_path)

    @adapter = Redmine::Scm::Adapters::FilesystemAdapter.new(fs_repository_path)
  end

  it 'should entries' do
    assert_equal 3, @adapter.entries.size
    assert_equal ['dir', 'japanese', 'test'], @adapter.entries.map(&:name)
    assert_equal ['dir', 'japanese', 'test'], @adapter.entries(nil).map(&:name)
    assert_equal ['dir', 'japanese', 'test'], @adapter.entries('/').map(&:name)
    ['dir', '/dir', '/dir/', 'dir/'].each do |path|
      assert_equal ['subdir', 'dirfile'], @adapter.entries(path).map(&:name)
    end
    # If y try to use "..", the path is ignored
    ['/../', 'dir/../', '..', '../', '/..', 'dir/..'].each do |path|
      assert_equal ['dir', 'japanese', 'test'], @adapter.entries(path).map(&:name),
                   '.. must be ignored in path argument'
    end
  end

  it 'should cat' do
    assert_equal "TEST CAT\n", @adapter.cat('test')
    assert_equal "TEST CAT\n", @adapter.cat('/test')
    # Revision number is ignored
    assert_equal "TEST CAT\n", @adapter.cat('/test', 1)
  end
end
