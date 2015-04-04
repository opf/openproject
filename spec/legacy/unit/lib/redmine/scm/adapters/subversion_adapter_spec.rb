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

describe Redmine::Scm::Adapters::SubversionAdapter, type: :model do
  if repository_configured?('subversion')
    before do
      @adapter = Redmine::Scm::Adapters::SubversionAdapter.new(self.class.subversion_repository_url)
    end

    it 'should client version' do
      v = Redmine::Scm::Adapters::SubversionAdapter.client_version
      assert v.is_a?(Array)
    end

    it 'should scm version' do
      to_test = { "svn, version 1.6.13 (r1002816)\n"  => [1, 6, 13],
                  "svn, versione 1.6.13 (r1002816)\n" => [1, 6, 13],
                  "1.6.1\n1.7\n1.8"                   => [1, 6, 1],
                  "1.6.2\r\n1.8.1\r\n1.9.1"           => [1, 6, 2] }
      to_test.each do |s, v|
        test_scm_version_for(s, v)
      end
    end

    private

    def test_scm_version_for(scm_version, version)
      expect(@adapter.class).to receive(:scm_version_from_command_line).and_return(scm_version)
      assert_equal version, @adapter.class.svn_binary_version
    end

  else
    puts 'Subversion test repository NOT FOUND. Skipping unit tests !!!'
    it 'should fake' do; assert true end
  end
end
