module API
  module V3
    module WorkPackages
      class UpdateEndPoint < API::V3::Utilities::Endpoints::Update
        def present_success(current_user, call)
          call.result.reload

          super
        end
      end
    end
  end
end
