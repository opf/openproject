module Api
  module V1

    class NewsController < NewsController

      include ::Api::V1::ApiController

      def index
        case params[:format]
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
        else
          @limit =  10
        end

        scope = @project ? @project.news.visible : News.visible

        @news_count = scope.count
        @news_pages = Paginator.new self, @news_count, @limit, params['page']
        @offset ||= @news_pages.current.offset
        @newss = scope.all(:include => [:author, :project],
                                        :order => "#{News.table_name}.created_on DESC",
                                        :offset => @offset,
                                        :limit => @limit)

        respond_to do |format|
          format.api
        end
      end

    end
  end
end
