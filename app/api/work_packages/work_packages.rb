module WorkPackages
  class API < Grape::API

    resources :work_packages do

      get do
        'list all work packages'
      end

      post do
        'create new work package(s)'
      end

      patch do
        'batch update work packages'
      end

      delete do
        'batch delete work packages'
      end

      params do
        requires :id, type: Integer, desc: 'Work package id.'
      end
      namespace ':id' do

        before do
          @work_package = WorkPackage.find(params[:id])
        end

        get do
          'show a work package'
        end

        put do
          'update a work package (provide whole resource)'
        end

        patch do
          @work_package
        end

        delete do
          'delete a work package'
        end
      end

    end
  end
end
