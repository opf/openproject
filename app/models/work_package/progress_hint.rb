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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Hint to be displayed in the progress popover under a progress value.
#
# `key` is like `field_name`.`hint` and is used to build up the translation
# key. `params` is the translation parameters as some translation are
# parameterized.
class WorkPackage
  ProgressHint = Data.define(:key, :params) do
    def initialize(key:, params: {})
      super
    end

    def message
      I18n.t("work_package.progress.derivation_hints.#{key}", **to_hours(params))
    end

    def reason
      key.split(".", 2).last
    end

    def to_hours(params)
      params.transform_values { |value| DurationConverter.output(value.abs) }
    end
  end
end
