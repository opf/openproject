#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

##
# The following bit of code patches rspec to accept i18n codes in all finders and when looking for text.
# This way labels don't have to be hardcoded which means they can be changed without breaking tests.
# Examples:
#
#   Given I click on "t:account.delete"
#   When I follow "t:label_register"
#   And I press "t:button_login"
#
# Where the i18n file contains the following:
#
#   en:
#     label_register: "Sign up"
#     label_button_login: "Sign in"
#
#     account:
#       delete: "Delete account"
#
if Rails.env.test?
  require 'capybara'
  require 'capybara/rspec/matchers'

  Capybara::Node::Finders.module_eval do
    def find_with_i18n(*args)
      i18n = args[1]
      if args.size >= 2 && i18n.is_a?(String) && i18n =~ /^t:[^\s]/
        begin
          args[1] = I18n.t(i18n.split(":").last)
          find_without_i18n(*args)
        rescue Capybara::ElementNotFound
          # perhaps it was not intended to be an i18n code after all
          args[1] = i18n
          find_without_i18n(*args)
        end
      else
        find_without_i18n(*args)
      end
    end

    alias_method_chain :find, :i18n
  end

  Capybara::RSpecMatchers::HaveText.module_eval do
    def matches_with_i18n?(actual)
      if content.is_a?(String) && content =~ /^t:[^\s]/
        i18n = content
        @content = I18n.t(i18n.split(":").last)
        matches_without_i18n?(actual) || begin
          # perhaps it was not intended to be an i18n code after all
          @content = i18n
          matches_without_i18n?(actual)
        end
      else
        matches_without_i18n?(actual)
      end
    end

    alias_method_chain :matches?, :i18n
  end
end
