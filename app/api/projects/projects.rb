module Projects
  class API < Grape::API

    resources :projects do
      get do
        projects = Project.all
        projects_array = []
        projects.each do |project|
          resource = ProjectMapper.new(project).to_resource
          projects_array << Yaks::HalSerializer.new(resource).serialize
        end
        json = {
          _collection: projects_array,
          _type: "Project",
          _links: {
              root: { href: '/api/v3' },
              self: { href: '/api/v3/projects' },
              next: { href: '/api/v3/projects/page=3' },
              previous: { href: '/api/v3/projects/page=1' },
              first: { href: '/api/v3/projects/page=1' },
              last: { href: '/api/v3/projects/page=102' },
              create: { href: '/api/v3/projects,', method: 'post' },
              batchUpdate: { href: '/api/v3/projects', method: 'delete' },
              batchDelete: { href: '/api/v3/projects?{ids}', method: 'delete' },

           },
          _count: projects_array.count,
          _total: Project.count
        }.to_json
      end

      get ':id' do
        project = Project.find(params[:id])
        resource = ProjectMapper.new(project).to_resource
        Yaks::HalSerializer.new(resource).serialize.to_json
      end

      patch ':id' do
      end

      delete :':id' do
      end

      patch do
      end

      delete do
      end

    end
  end
end
