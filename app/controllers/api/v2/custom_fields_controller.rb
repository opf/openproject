module Api
  module V2
    class CustomFieldsController < ApplicationController

      include ::Api::V2::ApiController

      def index
        @custom_fields = CustomField.find :all,
            :offset => params[:offset],
            :limit => params[:limit]

        respond_to do |format|
          format.api
        end
      end

      def show
        @custom_field = CustomField.find params[:id]

        respond_to do |format|
          format.api
        end
      end

    end
  end
end
