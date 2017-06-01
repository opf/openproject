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

#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class ResetTest < Test::Unit::TestCase
  context 'Resetting a model' do
    setup do
      @original_dependent = User.reflect_on_association(:journals).options[:dependent]
      @user = User.new
      @journals = []
      @names = ['Steve Richert', 'Stephen Richert', 'Stephen Jobs', 'Steve Jobs']
      @names.each do |name|
        @user.update_attribute(:name, name)
        @journals << @user.journal
      end
    end

    should "properly revert the model's attributes" do
      @journals.reverse.each_with_index do |journal, i|
        @user.reset_to!(journal)
        assert_equal @names.reverse[i], @user.name
      end
    end

    should 'dissociate all journals after the target' do
      @journals.reverse_each do |journal|
        @user.reset_to!(journal)
        assert_equal 0, @user.journals(true).after(journal).count
      end
    end

    context 'with the :dependent option as :delete_all' do
      setup do
        User.reflect_on_association(:journals).options[:dependent] = :delete_all
      end

      should 'delete all journals after the target journal' do
        @journals.reverse_each do |journal|
          later_journals = @user.journals.after(journal)
          @user.reset_to!(journal)
          later_journals.each do |later_journal|
            assert_raise ActiveRecord::RecordNotFound do
              later_journal.reload
            end
          end
        end
      end

      should 'not destroy all journals after the target journal' do
        VestalVersions::Version.any_instance.stub(:destroy).and_raise(RuntimeError)
        @journals.reverse_each do |journal|
          assert_nothing_raised do
            @user.reset_to!(journal)
          end
        end
      end
    end

    context 'with the :dependent option as :destroy' do
      setup do
        User.reflect_on_association(:journals).options[:dependent] = :destroy
      end

      should 'delete all journals after the target journal' do
        @journals.reverse_each do |journal|
          later_journals = @user.journals.after(journal)
          @user.reset_to!(journal)
          later_journals.each do |later_journal|
            assert_raise ActiveRecord::RecordNotFound do
              later_journal.reload
            end
          end
        end
      end

      should 'destroy all journals after the target journal' do
        VestalVersions::Version.any_instance.stub(:destroy).and_raise(RuntimeError)
        @journals.reverse_each do |journal|
          later_journals = @user.journals.after(journal)
          if later_journals.empty?
            assert_nothing_raised do
              @user.reset_to!(journal)
            end
          else
            assert_raise RuntimeError do
              @user.reset_to!(journal)
            end
          end
        end
      end
    end

    context 'with the :dependent option as :nullify' do
      setup do
        User.reflect_on_association(:journals).options[:dependent] = :nullify
      end

      should 'leave all journals after the target journal' do
        @journals.reverse_each do |journal|
          later_journals = @user.journals.after(journal)
          @user.reset_to!(journal)
          later_journals.each do |later_journal|
            assert_nothing_raised do
              later_journal.reload
            end
          end
        end
      end
    end

    teardown do
      User.reflect_on_association(:journals).options[:dependent] = @original_dependent
    end
  end
end
