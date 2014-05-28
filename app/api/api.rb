class API < Grape::API
  include Pundit

  content_type 'hal+json', 'application/hal+json'
  format 'hal+json'

  cascade false

  helpers do
    def current_user
      user_id = env['action_dispatch.request.unsigned_session_cookie']['user_id']
      return nil if user_id.nil?
      @current_user ||= User.find(user_id)
    end

    def authorize(api, endpoint, project = nil, projects = nil, global = false)
      is_authorized = AuthorizationService.new(api, endpoint, project, projects, global, current_user).perform

      unless is_authorized
        # error!('403 Forbidden', 403)
      end
      is_authorized
    end

     def root_url
        'http://localhost:3000/api/v3'
     end

     def rels_url
        "#{root_url}/rels"
     end
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    binding.pry
    errors = []
    e.errors.each do |key, value|
      errors  << { key => value.map{ |e| e.message } }
    end
    Rack::Response.new(
      {
        title: :validation_error,
        description: 'The object did not pass validation',
        errors: errors
      }.to_json, 422, { "Content-Type" => "application/hal+json" }).finish
  end

  get do
    {
      _links: {
        self: {
          href: "#{root_url}",
          title: "OpenProject API entry point."
        },
        "#{rels_url}" => {
          href: "#{rels_url}",
          title: "Custom link relationships supported by OpenProject API."
        },
        "#{rels_url}/work_packages" => {
          href: "#{root_url}/work_packages",
          title: "Your work packages."
        }
      },
      message: "Welcome to OpenProject Hypermedia API"
    }.to_json
  end

  mount Projects::API
  mount WorkPackages::API
  mount Users::API
end
