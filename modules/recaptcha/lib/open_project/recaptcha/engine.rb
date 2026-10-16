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

require "open_project/plugins"
require "recaptcha"

module OpenProject::Recaptcha
  class Engine < ::Rails::Engine
    engine_name :openproject_recaptcha

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-recaptcha",
             author_url: "https://www.openproject.org",
             # TODO: secret_key should be marked as `secret: true`, but that is only supported
             # for string settings, not for keys inside this plugin settings hash.
             settings: {
               default: {
                 recaptcha_type: ::OpenProject::Recaptcha::TYPE_DISABLED,
                 response_limit: 5000
               }
             },
             bundled: true do
      menu :admin_menu,
           :plugin_recaptcha,
           { controller: "/recaptcha/admin", action: :show },
           parent: :authentication,
           caption: ->(*) { I18n.t("recaptcha.label_recaptcha") }
    end

    initializer "openproject.configuration" do
      ::Settings::Definition.add OpenProject::Recaptcha::Configuration::CONFIG_KEY, default: false
    end

    config.after_initialize do
      OpenProject::Authentication::Stage.register(
        :recaptcha,
        nil,
        run_after_activation: true,
        active: -> { OpenProject::Recaptcha.enabled? }
      ) do
        recaptcha_request_path
      end
    end
  end
end
