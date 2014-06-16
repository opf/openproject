module API
  module V3
    module Queries
      class QueriesAPI < Grape::API

        resources :queries do

          params do
            requires :id, desc: 'Query id'
          end
          namespace ':id' do

            before do
              @query = Query.find(params[:id])
              model = QueryModel.new(query: @query)
              @representer =  QueryRepresenter.new(model)
            end

            patch :star do
              if !@query.is_public?
                raise API::Errors::Unauthorized.new(current_user) unless @query.user_id == current_user.id
                authorize(:queries, :star_private, @query.project)
              else
                authorize(:queries, :star, @query.project)
              end
              normalized_query_name = @query.name.parameterize.underscore
              query_menu_item = MenuItems::QueryMenuItem.find_or_initialize_by_name_and_navigatable_id normalized_query_name, @query.id, title: @query.name

              if query_menu_item.valid?
                query_menu_item.save!
                @representer.to_json
              else
                raise ValidationError.new(query_menu_item)
              end
            end

            patch :unstar do
              if !@query.is_public?
                raise API::Errors::Unauthorized.new(current_user) unless @query.user_id == current_user.id
                authorize(:queries, :unstar_private, @query.project)
              else
                authorize(:queries, :unstar, @query.project)
              end
              query_menu_item = @query.query_menu_item
              return @representer.to_json if @query.query_menu_item.nil?
              query_menu_item.destroy
              @query.reload
              @representer.to_json
            end
          end

        end

      end
    end
  end
end
