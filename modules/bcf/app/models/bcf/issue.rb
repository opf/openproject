module Bcf
  class Issue < ActiveRecord::Base
    include InitializeWithUuid

    belongs_to :work_package
    has_one :project, through: :work_package
    has_many :viewpoints, foreign_key: :issue_id, class_name: "Bcf::Viewpoint"
    has_many :comments,   foreign_key: :issue_id, class_name: "Bcf::Comment"

    after_update :invalidate_markup_cache

    validates :work_package, presence: true

    class << self
      def of_project(project)
        includes(:work_package)
          .references(:work_packages)
          .merge(WorkPackage.for_projects(project))
      end
    end

    def imported_title
      markup_doc.xpath('//Topic/Title').text
    end

    def markup_doc
      @markup_doc ||= Nokogiri::XML markup, nil, 'UTF-8'
    end

    def invalidate_markup_cache
      @markup_doc = nil
    end
  end
end
