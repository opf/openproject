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

module Bim::Bcf::API::V2_1
  module Comments
    class API < ::API::OpenProjectAPI
      resources :comments do
        helpers do
          def all_comments
            @issue.comments.includes(:journal, :issue, :viewpoint)
          end

          def get_viewpoint_by_uuid(viewpoint_uuid)
            if viewpoint_uuid == nil
              nil
            else
              @issue.viewpoints.find_by(uuid: viewpoint_uuid) || ::Bim::Bcf::NonExistentViewpoint.new
            end
          end

          def get_comment_by_uuid(comment)
            if comment == nil
              nil
            else
              @issue.comments.find_by(uuid: comment) || ::Bim::Bcf::NonExistentComment.new
            end
          end

          def transform_create_parameter(params)
            {
              issue: @issue,
              viewpoint: get_viewpoint_by_uuid(params[:viewpoint_guid]),
              reply_to: get_comment_by_uuid(params[:reply_to_comment_guid])
            }
          end

          def transform_update_parameter(params)
            {
              original_comment: @comment,
              viewpoint: get_viewpoint_by_uuid(params[:viewpoint_guid]),
              reply_to: get_comment_by_uuid(params[:reply_to_comment_guid])
            }
          end
        end

        get &::Bim::Bcf::API::V2_1::Endpoints::Index.new(model: Bim::Bcf::Comment, scope: -> { all_comments }).mount

        post &::Bim::Bcf::API::V2_1::Endpoints::Create
                .new(model: Bim::Bcf::Comment,
                     params_modifier: ->(params) { transform_create_parameter(params).merge(params) })
                .mount

        params do
          requires :comment_guid, type: String, desc: "The comment's UUID"
        end

        route_param :comment_guid, regexp: /\A[a-f0-9-]+\z/ do
          after_validation do
            @comment = all_comments.find_by!(uuid: declared_params[:comment_guid])
          end

          get &::Bim::Bcf::API::V2_1::Endpoints::Show.new(model: Bim::Bcf::Comment).mount

          put &::Bim::Bcf::API::V2_1::Endpoints::Update
                 .new(model: Bim::Bcf::Comment,
                      params_modifier: ->(params) { transform_update_parameter(params).merge(params) })
                 .mount
        end
      end
    end
  end
end
