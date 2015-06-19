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

#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class ConfigurationTest < Test::Unit::TestCase
  context 'Global configuration options' do
    setup do
      module Extension; end

      @options = {
        'class_name' => 'CustomVersion',
        extend: Extension,
        as: :parent
      }

      VestalVersions.configure do |config|
        @options.each do |key, value|
          config.send("#{key}=", value)
        end
      end

      @configuration = VestalVersions::Configuration.options
    end

    should 'should be a hash' do
      assert_kind_of Hash, @configuration
    end

    should 'have symbol keys' do
      assert @configuration.keys.all? { |k| k.is_a?(Symbol) }
    end

    should 'store values identical to those given' do
      assert_equal @options.symbolize_keys, @configuration
    end

    teardown do
      VestalVersions::Configuration.options.clear
    end
  end
end
