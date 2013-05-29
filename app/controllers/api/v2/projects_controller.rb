module Api
  module V2
    class ProjectsController < ProjectsController

      include ::Api::V2::ApiController

      def index
        options = {:order => 'lft'}

        if params[:ids]
          ids, identifiers = params[:ids].split(/,/).map(&:strip).partition { |s| s =~ /^\d*$/ }
          ids = ids.map(&:to_i).sort
          identifiers = identifiers.sort

          options[:conditions] = ["id IN (?) OR identifier IN (?)", ids, identifiers]
        end

        @projects = @base.visible.all(options)
        respond_to do |format|
          format.api
        end
      end

      def show
        @project = @base.find(params[:id])
        authorize
        return if performed?

        respond_to do |format|
          format.api
        end
      end
    end
  end
end
