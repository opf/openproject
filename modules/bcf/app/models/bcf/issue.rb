module Bcf
  class Issue < ActiveRecord::Base
    include InitializeWithUuid

    belongs_to :work_package
    has_one :project, through: :work_package
    has_many :viewpoints, foreign_key: :issue_id, class_name: "Bcf::Viewpoint"
    has_many :comments,   foreign_key: :issue_id, class_name: "Bcf::Comment"

    after_update :invalidate_markup_cache

    class << self
      def with_markup
        select '*',
               extract_first_node(title_path, 'title'),
               extract_first_node(description_path, 'description'),
               extract_first_node(priority_text_path, 'priority_text'),
               extract_first_node(status_text_path, 'status_text'),
               extract_first_node(type_text_path, 'type_text'),
               extract_first_node(assignee_text_path, 'assignee_text'),
               extract_first_node(due_date_text_path, 'due_date_text'),
               extract_first_node(creation_date_text_path, 'creation_date_text'),
               extract_first_node(creation_author_text_path, 'creation_author_text'),
               extract_first_node(modified_date_text_path, 'modified_date_text'),
               extract_first_node(modified_author_text_path, 'modified_author_text'),
               extract_first_node(index_text_path, 'index_text'),
               extract_first_node(stage_text_path, 'stage_text'),
               extract_nodes(labels_path, 'labels')
      end

      def of_project(project)
        includes(:work_package)
          .references(:work_packages)
          .merge(WorkPackage.for_projects(project))
      end

      protected

      def title_path
        '/Markup/Topic/Title/text()'
      end

      def description_path
        '/Markup/Topic/Description/text()'
      end

      def priority_text_path
        '/Markup/Topic/Priority/text()'
      end

      def status_text_path
        '/Markup/Topic/@TopicStatus'
      end

      def type_text_path
        '/Markup/Topic/@TopicType'
      end

      def assignee_text_path
        '/Markup/Topic/AssignedTo/text()'
      end

      def due_date_text_path
        '/Markup/Topic/DueDate/text()'
      end

      def stage_text_path
        '/Markup/Topic/Stage/text()'
      end

      def creation_date_text_path
        '/Markup/Topic/CreationDate/text()'
      end

      def creation_author_text_path
        '/Markup/Topic/CreationAuthor/text()'
      end

      def modified_date_text_path
        '/Markup/Topic/ModifiedDate/text()'
      end

      def modified_author_text_path
        '/Markup/Topic/ModifiedAuthor/text()'
      end

      def index_text_path
        '/Markup/Topic/Index/text()'
      end

      def labels_path
        '/Markup/Topic/Labels/text()'
      end

      private

      def extract_first_node(path, as)
        "(xpath('#{path}', markup))[1] AS #{as}"
      end

      def extract_nodes(path, as)
        "(xpath('#{path}', markup)) AS #{as}"
      end
    end

    %i[title
       description
       priority_text
       status_text
       type_text
       assignee_text
       due_date_text
       creation_date_text
       creation_author_text
       modified_date_text
       modified_author_text
       stage_text
       index_text].each do |name|
      define_method name do
        from_attributes_or_doc name
      end
    end

    def labels
      from_attributes_or_doc :labels, multiple: true
    end

    def markup_doc
      @markup_doc ||= Nokogiri::XML markup, nil, 'UTF-8'
    end

    def invalidate_markup_cache
      @markup_doc = nil
    end

    private

    def from_attributes_or_doc(key, multiple: false)
      if attributes.keys.include? key.to_s
        self[key]
      else
        path = markup_doc.xpath(self.class.send("#{key}_path"))

        if multiple
          path.map(&:to_s)
        else
          path.first.to_s.presence
        end
      end
    end
  end
end
