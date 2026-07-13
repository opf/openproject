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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module HealthReports
  class ResultComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(group:, result:, i18n_scope:)
      super(result)
      @group = group
      @i18n_scope = i18n_scope
    end

    private

    def text = I18n.t("#{@group}.#{model.key}", scope: @i18n_scope)

    def error_text
      return nil if model.code.nil?

      # TODO: fix translation namespace
      I18n.t("errors.#{model.code}", scope: @i18n_scope, **model.context&.symbolize_keys)
    end

    def docs_href = ::OpenProject::Static::Links.url_for(:storage_docs, :health_status)

    def error_code
      if model.failure?
        "ERR_#{model.code.upcase}"
      elsif model.warning?
        "WRN_#{model.code.upcase}"
      end
    end

    def status_color
      if model.success?
        :success
      elsif model.failure?
        :danger
      elsif model.warning? || model.skipped?
        :attention
      else
        raise ArgumentError, "invalid check result state"
      end
    end

    def status_text
      if model.success?
        t(".status.passed")
      elsif model.failure?
        t(".status.failed")
      elsif model.warning?
        t(".status.warning")
      elsif model.skipped?
        t(".status.skipped")
      else
        raise ArgumentError, "invalid check result state"
      end
    end
  end
end
