# frozen_string_literal: true

module API
  module V3
    module Bim
      class ApiTokensController < ApplicationController
        before_action :require_login
        before_action :find_token, only: %i[show update destroy revoke]

        # GET /api/v3/bim/api_tokens
        def index
          tokens = current_user.api_tokens.recent

          render json: {
            _type: 'Collection',
            total: tokens.count,
            count: tokens.size,
            _embedded: {
              elements: tokens.map { |token| token_representer(token) }
            }
          }
        end

        # POST /api/v3/bim/api_tokens
        def create
          token, plain_token = Bim::ApiToken.generate(
            user: current_user,
            name: params[:name],
            project: params[:project_id] ? Project.find(params[:project_id]) : nil,
            scopes: params[:scopes] || [],
            expires_in: params[:expires_in]&.to_i
          )

          # Log API key creation
          Bim::AuditLog.log(
            user: current_user,
            project: token.project || current_user.projects.first,
            action: :api_key_created,
            details: { token_name: token.name, scopes: token.scopes }
          )

          render json: {
            _type: 'ApiToken',
            **token_representer(token),
            token: plain_token, # Only shown once!
            warning: 'Save this token now. You won\'t be able to see it again!'
          }, status: :created
        end

        # GET /api/v3/bim/api_tokens/:id
        def show
          render json: token_representer(@token)
        end

        # PATCH /api/v3/bim/api_tokens/:id
        def update
          if @token.update(update_params)
            render json: token_representer(@token)
          else
            render json: { errors: @token.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/api_tokens/:id/revoke
        def revoke
          @token.revoke!

          # Log API key revocation
          Bim::AuditLog.log(
            user: current_user,
            project: @token.project || current_user.projects.first,
            action: :api_key_revoked,
            details: { token_name: @token.name }
          )

          render json: {
            message: 'API token revoked successfully',
            token: token_representer(@token)
          }
        end

        # DELETE /api/v3/bim/api_tokens/:id
        def destroy
          @token.destroy
          head :no_content
        end

        private

        def find_token
          @token = current_user.api_tokens.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'API token not found' }, status: :not_found
        end

        def update_params
          params.permit(:name, :description, :active, scopes: [])
        end

        def token_representer(token)
          token.to_hash
        end
      end
    end
  end
end
