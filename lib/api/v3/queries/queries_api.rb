module API
  module V3
    module Queries
      class QueriesAPI < Grape::API

        resources :queries do

          params do
            requires :id, desc: 'Query id'
          end
          namespace ':id' do

            get do
              { query: 'query' }.to_json
            end

          end

        end

      end
    end
  end
end
