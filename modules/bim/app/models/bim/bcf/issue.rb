module Bim::Bcf
  class Issue < ActiveRecord::Base
    self.table_name = :bcf_issues

    include InitializeWithUuid
    include VirtualAttribute

    SETTABLE_ATTRIBUTES = %i[stage labels index reference_links bim_snippet].freeze

    belongs_to :work_package
    has_one :project, through: :work_package
    has_many :viewpoints, foreign_key: :issue_id, class_name: "Bim::Bcf::Viewpoint", dependent: :destroy
    has_many :comments, foreign_key: :issue_id, class_name: "Bim::Bcf::Comment", dependent: :destroy

    after_update :invalidate_markup_cache

    validates :work_package, presence: true
    validates_uniqueness_of :uuid, message: :uuid_already_taken

    # The virtual attributes are defined so that an API client can attempt to set them.
    # However, currently such information is not persisted. But adding them fits better into the code
    # and might later on be replaced by an actual storing..
    virtual_attribute :reference_links do
      []
    end

    virtual_attribute :bim_snippet do
      {}
    end

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
