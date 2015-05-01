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

class ConditionsTest < Test::Unit::TestCase
  context 'Converted :if conditions' do
    setup do
      User.class_eval do
        def true; true; end
      end
    end

    should 'be an array' do
      assert_kind_of Array, User.vestal_journals_options[:if]
      User.prepare_journaled_options(if: :true)
      assert_kind_of Array, User.vestal_journals_options[:if]
    end

    should 'have proc values' do
      User.prepare_journaled_options(if: :true)
      assert User.vestal_journals_options[:if].all? { |i| i.is_a?(Proc) }
    end

    teardown do
      User.prepare_journaled_options(if: [])
    end
  end

  context 'Converted :unless conditions' do
    setup do
      User.class_eval do
        def true; true; end
      end
    end

    should 'be an array' do
      assert_kind_of Array, User.vestal_journals_options[:unless]
      User.prepare_journaled_options(unless: :true)
      assert_kind_of Array, User.vestal_journals_options[:unless]
    end

    should 'have proc values' do
      User.prepare_journaled_options(unless: :true)
      assert User.vestal_journals_options[:unless].all? { |i| i.is_a?(Proc) }
    end

    teardown do
      User.prepare_journaled_options(unless: [])
    end
  end

  context 'A new journal' do
    setup do
      User.class_eval do
        def true; true; end

        def false; false; end
      end

      @user = User.create(name: 'Steve Richert')
      @count = @user.journals.count
    end

    context 'with :if conditions' do
      context 'that pass' do
        setup do
          User.prepare_journaled_options(if: [:true])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'be created' do
          assert_equal @count + 1, @user.journals.count
        end
      end

      context 'that fail' do
        setup do
          User.prepare_journaled_options(if: [:false])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end
    end

    context 'with :unless conditions' do
      context 'that pass' do
        setup do
          User.prepare_journaled_options(unless: [:true])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end

      context 'that fail' do
        setup do
          User.prepare_journaled_options(unless: [:false])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count + 1, @user.journals.count
        end
      end
    end

    context 'with :if and :unless conditions' do
      context 'that pass' do
        setup do
          User.prepare_journaled_options(if: [:true], unless: [:true])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end

      context 'that fail' do
        setup do
          User.prepare_journaled_options(if: [:false], unless: [:false])
          @user.update_attribute(:last_name, 'Jobs')
        end

        should 'not be created' do
          assert_equal @count, @user.journals.count
        end
      end
    end

    teardown do
      User.prepare_journaled_options(if: [], unless: [])
    end
  end
end
