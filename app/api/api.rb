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
        query ||= params[:action].to_s + "?"
        @_policy_authorized = true

        policy = Pundit.policy(current_user, record)
        unless policy.public_send(query)
          error = NotAuthorizedError.new("not allowed to #{query} this #{record}")
          error.query, error.record, error.policy = query, record, policy

          raise error
        end

        true
       end
    end

  get do
    "Entry point"
  end

  get :search do
    "search"
  end

  mount WorkPackages::API
  mount Users::API
end
