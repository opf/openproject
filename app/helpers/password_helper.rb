#-- encoding: UTF-8
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

module PasswordHelper
  include Concerns::PasswordConfirmation

  ##
  # Decorate the form_for helper with the request-for-confirmation directive
  # when the user is internally authenticated.
  def password_confirmation_form_for(record, options = {}, &block)
    if password_confirmation_required?
      options.reverse_merge!(html: {})
      data = options[:html].fetch(:data, {})
      data[:'request-for-confirmation'] = ''

      options[:html][:data] = data
    end

    form_for(record, options, &block)
  end

  ##
  # Decorate the form_tag helper with the request-for-confirmation directive
  # when the user is internally authenticated.
  def password_confirmation_form_tag(url_for_options = {}, options = {}, &block)
    if password_confirmation_required?
      data = options.fetch(:data, {})
      data[:'request-for-confirmation'] = ''

      options[:data] = data
    end

    form_tag(url_for_options, options, &block)
  end

  def render_password_complexity_tooltip
    rules = password_rules_description

    s = OpenProject::Passwords::Evaluator.min_length_description
    s += "<br> #{rules}" if rules.present?

    s.html_safe
  end

  private

  # Return a HTML list with active password complexity rules
  def password_active_rules
    rules = OpenProject::Passwords::Evaluator.active_rules_list
    content_tag :ul do
      rules.map { |item| concat(content_tag(:li, item)) }
    end
  end

  # Returns a text describing the active password complexity rules,
  # the minimum number of rules to adhere to and the total number of rules.
  def password_rules_description
    return '' if OpenProject::Passwords::Evaluator.min_adhered_rules == 0
    OpenProject::Passwords::Evaluator.rules_description_locale(password_active_rules)
  end
end
