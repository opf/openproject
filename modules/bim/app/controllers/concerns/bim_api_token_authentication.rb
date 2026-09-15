# frozen_string_literal: true

module BimApiTokenAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_from_api_token
  end

  private

  def authenticate_from_api_token
    return if current_user # Already authenticated via session

    # Check for API token in Authorization header
    token = extract_token_from_header

    return unless token

    # Authenticate using API token adapter
    user = Bim::Authentication::Manager.authenticate(
      api_token: token,
      ip_address: request.remote_ip
    )

    if user
      # Set current user for this request
      User.current = user
      @current_user = user
    else
      render_api_token_error
    end
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header

    # Support both "Bearer TOKEN" and "Token TOKEN" formats
    if auth_header.start_with?('Bearer ')
      auth_header.sub('Bearer ', '')
    elsif auth_header.start_with?('Token ')
      auth_header.sub('Token ', '')
    else
      auth_header
    end
  end

  def render_api_token_error
    render json: {
      error: 'Invalid or expired API token',
      message: 'Please provide a valid API token in the Authorization header'
    }, status: :unauthorized
  end

  # Check if current request is using API token authentication
  def api_token_request?
    request.headers['Authorization'].present?
  end

  # Verify API token has required scope
  def verify_api_token_scope(scope)
    return true unless api_token_request?

    token_string = extract_token_from_header
    token = Bim::ApiToken.find_by_token(token_string)

    unless token&.has_scope?(scope)
      render json: {
        error: 'Insufficient permissions',
        message: "This API token does not have '#{scope}' scope"
      }, status: :forbidden
      return false
    end

    true
  end
end
