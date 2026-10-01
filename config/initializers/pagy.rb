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

# Pagy initializer file (43.6.3)
# See https://ddnexus.github.io/pagy/toolbox/configuration/initializer/

############ Global Options ################################################################
# See https://ddnexus.github.io/pagy/toolbox/configuration/options/ for details.
# Examples:
#
# Pagy::OPTIONS[:limit]     = 10     # Limit the items per page
# Pagy::OPTIONS[:client_limit] = 100    # The client is allowed to request a limit up to 100
# Pagy::OPTIONS[:jsonapi]   = true   # Use JSON:API compliant URLs

Pagy::OPTIONS.freeze

############ JS and CSS Resources ##########################################################
# See https://ddnexus.github.io/pagy/resources/javascript/
# and https://ddnexus.github.io/pagy/resources/stylesheets/ for details.
# Sync example:
#
# if Rails.env.development?
#   Pagy.sync(:javascript, Rails.root.join('app/javascript'), 'pagy.mjs')
#   Pagy.sync(:stylesheet, Rails.root.join('app/stylesheets'), 'pagy.css')
# end
#
# Pipeline example:
#
# Rails.application.config.assets.paths << Pagy::ROOT.join(':javascripts')
# Rails.application.config.assets.paths << Pagy::ROOT.join(':stylesheets')

############# Overriding Pagy::I18n Lookup #################################################
# See https://ddnexus.github.io/pagy/resources/i18n/ for details.
# Example for Rails:
#
# Pagy::I18n.pathnames << Rails.root.join('config/locales/pagy')

############# I18n Gem Translation #########################################################
# See https://ddnexus.github.io/pagy/resources/i18n/ for details.
#
# Pagy.translate_with_the_slower_i18n_gem!

############# Calendar Localization for non-en locales ####################################
# See https://ddnexus.github.io/pagy/toolbox/paginators/calendar#localization for details.
#
# Pagy::Calendar.localize_with_rails_i18n_gem(*your_locales)
