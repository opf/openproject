# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec::Matchers.define :have_enterprise_banner do |plan, **args|
  include TestSelectorFinders

  match do |page|
    if plan
      plan_name = I18n.t("ee.upsell.plan_name", plan: plan.capitalize)
      expected_text = I18n.t("ee.upsell.plan_text_html", plan_name:)
      args[:text] = expected_text
    end

    page.find(test_selector("op-enterprise-banner"), **args)
  end

  match_when_negated do |page|
    page.has_no_selector?(test_selector("op-enterprise-banner"), **args)
  end

  failure_message do
    <<~MESSAGE
      Expected page to have Enterprise banner, but it is absent or invisible.
    MESSAGE
  end

  failure_message_when_negated do
    banner_text = page.find(test_selector("op-enterprise-banner")).text
    <<~MESSAGE
      Expected page not to have Enterprise banner, but it is present and visible.
      Enterprise banner text:
        #{banner_text.gsub("\n", "\n  ")}
    MESSAGE
  end
end
