#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module PasswordHelper
  include PasswordConfirmation

  ##
  # Decorate the form_for helper with the request-for-confirmation directive
  # when the user is internally authenticated.
  def password_confirmation_form_for(record, options = {}, &)
    if password_confirmation_required?
      options.reverse_merge!(html: {})
      data = options[:html].fetch(:data, {})
      options[:html][:data] = password_confirmation_data_attribute(data)
    end

    form_for(record, options, &)
  end

  ##
  # Decorate the form_tag helper with the request-for-confirmation directive
  # when the user is internally authenticated.
  def password_confirmation_form_tag(url_for_options = {}, options = {}, &)
    if password_confirmation_required?
      data = options.fetch(:data, {})
      options[:data] = password_confirmation_data_attribute(data)
    end

    form_tag(url_for_options, options, &)
  end

  def password_confirmation_data_attribute(with_data = {})
    if password_confirmation_required?
      with_data.merge('request-for-confirmation': true)
    else
      with_data
    end
  end

  def render_password_complexity_hint
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
