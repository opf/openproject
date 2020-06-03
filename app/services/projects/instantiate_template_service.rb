#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Projects
  class InstantiateTemplateService < ::BaseServices::Create
    attr_reader :template_id

    def initialize(user:, template_id:)
      @template_id = template_id

      super user: user,
            contract_class: Projects::InstantiateTemplateContract,
            contract_options: { template_project_id: template_id }
    end

    def after_validate(params, call)
      ::CopyProjectJob.perform_later(
        user_id: user.id,
        source_project_id: template_id,
        target_project_params: project_params(params),
        # Copy all associations
        associations_to_copy: nil,
        # Send mails for now until we send our own mails
        send_mails: true
      )

      call
    end

    # Do not actually try to save the project here
    # but simply pass the previous call
    def persist(call)
      call
    end

    private

    ##
    # Modifies params to ensure we unset
    # the templated option
    def project_params(params)
      params.to_h.merge(
        templated: false
      )
    end
  end
end
