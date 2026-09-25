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

module API
  module V3
    module HourlyRates
      class HourlyRatesByPrincipalAPI < ::API::OpenProjectAPI
        resource :hourly_rates do
          helpers do
            # Project rates are limited to the projects the current user may see
            # rates in; the default rate has no project to gate it.
            def visible_rates
              project_rates = ::HourlyRate
                                .for_principal(@principal)
                                .in_project(::HourlyRate.projects_with_visible_rates(@principal))

              ::Rate.where(id: project_rates)
                    .or(::Rate.where(id: ::DefaultHourlyRate.for_principal(@principal)))
                    .newest_first
            end

            # A payload naming a project asks for a rate in that project,
            # anything else for the principal's default rate.
            def rate_class_from_payload
              request_body&.dig("_links", "project", "href").present? ? ::HourlyRate : ::DefaultHourlyRate
            end

            # Both rate classes are presented as one resource, so the endpoints
            # are told which representers to use instead of deducing them, and
            # which record to act on instead of guessing the ivar from the model.
            def mount_write_endpoint(endpoint_class, model:, **)
              instance_exec(&endpoint_class.new(
                model:,
                api_name: "HourlyRate",
                parse_representer: ::API::V3::HourlyRates::HourlyRatePayloadRepresenter,
                render_representer: ::API::V3::HourlyRates::HourlyRateRepresenter,
                params_modifier: ->(params) { params.merge(user_id: @principal.id) },
                **
              ).mount)
            end

            def mount_delete_endpoint
              instance_exec(&::API::V3::Utilities::Endpoints::Delete.new(
                model: @hourly_rate.class,
                api_name: "HourlyRate",
                instance_generator: ->(*) { @hourly_rate }
              ).mount)
            end
          end

          after_validation do
            raise ::API::Errors::NotFound unless @principal == current_user ||
              current_user.allowed_in_any_project?(:view_hourly_rates)
          end

          get do
            HourlyRateCollectionRepresenter.new(
              visible_rates,
              self_link: api_v3_paths.hourly_rates_by_principal(@principal.id),
              current_user:
            )
          end

          post do
            mount_write_endpoint(::API::V3::Utilities::Endpoints::Create, model: rate_class_from_payload)
          end

          route_param :rate_id, type: Integer, desc: "Rate ID" do
            after_validation do
              @hourly_rate = visible_rates.find(declared_params[:rate_id])
            end

            get do
              HourlyRateRepresenter.new(@hourly_rate, current_user:)
            end

            patch do
              mount_write_endpoint(::API::V3::Utilities::Endpoints::Update,
                                   model: @hourly_rate.class,
                                   instance_generator: ->(*) { @hourly_rate })
            end

            delete do
              mount_delete_endpoint
            end
          end
        end
      end
    end
  end
end
