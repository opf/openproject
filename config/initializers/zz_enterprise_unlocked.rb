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

# Fork-local override: unlocks every Enterprise feature without a token.
# Kept in a separate file so upstream merges into EnterpriseToken stay conflict-free.
module EnterpriseUnlocked
  module TokenClassMethods
    def all_features
      OpenProject::Token::FEATURES_PER_PLAN.values.reduce(:|)
    end

    def allows_to?(_feature) = true
    def available_features = all_features
    def non_trialling_features = all_features
    def hide_banners? = true
  end

  module EnterpriseService
    def call(_feature)
      ServiceResult.new(success: true, result: true)
    end
  end
end

Rails.application.config.to_prepare do
  EnterpriseToken.singleton_class.prepend(EnterpriseUnlocked::TokenClassMethods)
  Authorization::EnterpriseService.prepend(EnterpriseUnlocked::EnterpriseService)
end
