require 'roar/decorator'
require 'roar/representer/json/hal'

module WorkPackages
  class WorkPackagesRepresenter < Roar::Decorator
    include Roar::Representer::JSON::HAL
    include Roar::Representer::Feature::Hypermedia
    include Rails.application.routes.url_helpers

    self.as_strategy = CamelCasingStrategy.new

    link :self do
      { href: "http://localhost:3000/api/v3/work_packages", title: "Work packages" }
    end
    link :first do
      { href: "http://localhost:3000/api/v3/work_packages?offset=0", title: "Work packages" }
    end
    link :previous do
      { href: "http://localhost:3000/api/v3/work_packages?offset=0", title: "Work packages" }
    end
    link :next do
      { href: "http://localhost:3000/api/v3/work_packages?offset=0", title: "Work packages" }
    end
    link :last do
      { href: "http://localhost:3000/api/v3/work_packages?offset=0", title: "Work packages" }
    end

    property :_count, exec_context: :decorator
    property :_total, exec_context: :decorator
    property :limit, exec_context: :decorator
    property :offset, exec_context: :decorator
    property :_embedded, exec_context: :decorator

    def _count
      represented.length
    end

    def _total
      WorkPackage.count
    end

    def limit
      20
    end

    def offset
      0
    end

    def _embedded
      { work_packages:  represented.map { |r| WorkPackageRepresenter.new(r) } }
    end

    def _type
      "WorkPackage"
    end
  end
end
