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

require 'support/pages/page'

module Pages
  module Admin
    module CustomActions
      class Form < ::Pages::Page
        def set_name(name)
          fill_in 'Name', with: name
        end

        def add_action(name, value)
          within '#custom-actions-form--actions' do
            select name, from: 'Add'

            select value, from: name
          end
        end

        def remove_action(name)
          within '#custom-actions-form--active-actions' do
            find('.form--field', text: name)
              .find('.icon-close')
              .click
          end
        end

        def set_action(name, value)
          within '#custom-actions-form--active-actions' do
            field = find('.form--field', text: name)
            within field do
              select value, from: name
            end
          end
        rescue Capybara::ElementNotFound
          add_action(name, value)
        end

        def set_condition(name, value)
          within '#custom-actions-form--conditions' do
            select value, from: name
          end
        end
      end
    end
  end
end
