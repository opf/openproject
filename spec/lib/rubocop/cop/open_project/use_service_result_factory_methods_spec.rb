#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'
require 'rubocop/cop/open_project/use_service_result_factory_methods'

RSpec.describe RuboCop::Cop::OpenProject::UseServiceResultFactoryMethods do
  include RuboCop::RSpec::ExpectOffense
  include_context 'config'

  it 'registers an offense for ServiceResult.new without any success: argument' do
    expect_offense(<<~RUBY)
      ServiceResult.new
                    ^^^ Use ServiceResult.failure instead of ServiceResult.new.
      ServiceResult.new(errors: ['error'])
                    ^^^ Use ServiceResult.failure instead of ServiceResult.new.
    RUBY

    expect_correction(<<~RUBY)
      ServiceResult.failure
      ServiceResult.failure(errors: ['error'])
    RUBY
  end

  it 'allows ServiceResult.new(success: some_value) (no explicit true/false value)' do
    expect_no_offenses('ServiceResult.new(success: some_value)')
    expect_no_offenses('ServiceResult.new(foo: "bar", success: some_value, bar: "baz")')
  end

  it 'allows ServiceResult.new(**kw) (no explicit true/false value)' do
    expect_no_offenses('ServiceResult.new(**kw)')
    expect_no_offenses('ServiceResult.new(foo: "bar", **kw)')
    expect_no_offenses('ServiceResult.new(**kw, foo: "bar")')
  end

  include_context 'ruby 3.1' do
    it 'allows ServiceResult.new(success:) (no explicit true/false value)' do
      expect_no_offenses('ServiceResult.new(success:)')
      expect_no_offenses('ServiceResult.new(foo: "bar", success:, bar: "baz")')
    end

    it 'allows ServiceResult.new(...) (no explicit true/false value)' do
      expect_no_offenses(<<~RUBY)
        def call(...)
          ServiceResult.new(...)
        end
      RUBY
    end
  end

  it 'registers an offense for ServiceResult.new(success: true) with no additional args' do
    expect_offense(<<~RUBY)
      ServiceResult.new(success: true)
                        ^^^^^^^^^^^^^ Use ServiceResult.success(...) instead of ServiceResult.new(success: true, ...).
    RUBY

    expect_correction(<<~RUBY)
      ServiceResult.success
    RUBY
  end

  it 'registers an offense for ServiceResult.new(success: true) with additional args' do
    expect_offense(<<~RUBY)
      ServiceResult.new(success: true,
                        ^^^^^^^^^^^^^ Use ServiceResult.success(...) instead of ServiceResult.new(success: true, ...).
                        message: 'Great!')
      ServiceResult.new(message: 'Great!',
                        success: true)
                        ^^^^^^^^^^^^^ Use ServiceResult.success(...) instead of ServiceResult.new(success: true, ...).
    RUBY

    expect_correction(<<~RUBY)
      ServiceResult.success(message: 'Great!')
      ServiceResult.success(message: 'Great!')
    RUBY
  end

  it 'registers an offense for ServiceResult.new(success: false) with no additional args' do
    expect_offense(<<~RUBY)
      ServiceResult.new(success: false)
                        ^^^^^^^^^^^^^^ Use ServiceResult.failure(...) instead of ServiceResult.new(success: false, ...).
      ServiceResult.new success: false
                        ^^^^^^^^^^^^^^ Use ServiceResult.failure(...) instead of ServiceResult.new(success: false, ...).
    RUBY

    expect_correction(<<~RUBY)
      ServiceResult.failure
      ServiceResult.failure
    RUBY
  end

  it 'registers an offense for ServiceResult.new(success: false) with additional args' do
    expect_offense(<<~RUBY)
      ServiceResult.new(success: false,
                        ^^^^^^^^^^^^^^ Use ServiceResult.failure(...) instead of ServiceResult.new(success: false, ...).
                        errors: ['error'])
      ServiceResult.new(errors: ['error'],
                        success: false)
                        ^^^^^^^^^^^^^^ Use ServiceResult.failure(...) instead of ServiceResult.new(success: false, ...).
    RUBY

    expect_correction(<<~RUBY)
      ServiceResult.failure(errors: ['error'])
      ServiceResult.failure(errors: ['error'])
    RUBY
  end

  it 'registers an offense for ServiceResult.new(success: true/false) with splat kwargs' do
    expect_offense(<<~RUBY)
      ServiceResult.new(success: true, **kw)
                        ^^^^^^^^^^^^^ Use ServiceResult.success(...) instead of ServiceResult.new(success: true, ...).
      ServiceResult.new(success: false, **kw)
                        ^^^^^^^^^^^^^^ Use ServiceResult.failure(...) instead of ServiceResult.new(success: false, ...).
    RUBY

    expect_correction(<<~RUBY)
      ServiceResult.success(**kw)
      ServiceResult.failure(**kw)
    RUBY
  end
end
