module Api
  module V2

    class AuthenticationController < AuthenticationController

      unloadable

      def index
        respond_to do |format|
          format.api
        end
      end
    end

  end
end
