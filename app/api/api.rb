class API < Grape::API
  include Pundit

  use Rack::Session::Cookie
  content_type 'hal+json', 'application/hal+json'
  format 'hal+json'

  helpers do
      def current_user
        return nil if env['rack.session'][:user_id].nil?
        @current_user ||= User.find(env['rack.session'][:user_id])
      end

      def current_user=(user)
        env['rack.session'][:user_id] = user.id unless user
        @current_user = user
      end

      def authorize(record, query=nil)
        true
       end

       def root_url
          'http://localhost:3000/api/v3'
       end

       def rels_url
          "#{root_url}/rels"
       end
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
