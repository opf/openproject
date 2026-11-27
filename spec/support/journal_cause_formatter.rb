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

RSpec.shared_context "with journal cause formatter" do
  include ApplicationHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  let(:instance) { described_class.new(build(:work_package_journal)) }

  # we need to tell the url_helper that there is not controller to get url_options so that we can call link_to
  let(:controller) { nil }

  def render(cause, html:)
    if Journal::VALID_CAUSE_TYPES.exclude?(cause["type"])
      raise "#{cause['type'].inspect} is not a valid cause type from Journal::VALID_CAUSE_TYPES. " \
            "Please use one of #{Journal::VALID_CAUSE_TYPES}"
    end

    instance.render("cause", [nil, cause], html:)
  end
end

RSpec::Matchers.define :render_html_variant do |expected|
  match do |cause|
    @cause = cause
    @actual = render(cause, html: true)
    values_match? expected, @actual
  end

  description do
    "render HTML variant with #{surface_descriptions_in(expected).inspect}"
  end

  failure_message do |actual|
    "expected #{@cause} to render HTML variant as expected\n  " \
      "expected: #{surface_descriptions_in(expected).inspect}\n  " \
      "actual:   #{actual.inspect}"
  end
end

RSpec::Matchers.define :render_raw_variant do |expected|
  match do |cause|
    @cause = cause
    @actual = render(cause, html: false)
    values_match? expected, @actual
  end

  description do
    "render raw text variant with #{surface_descriptions_in(expected).inspect}"
  end

  failure_message do |actual|
    "expected #{@cause} to render raw text variant as expected\n  " \
      "expected: #{surface_descriptions_in(expected).inspect}\n  " \
      "actual:   #{actual.inspect}"
  end
end
