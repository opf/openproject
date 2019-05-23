module Bcf
  class Issue < ActiveRecord::Base
    include InitializeWithUuid

    belongs_to :work_package
    belongs_to :project

    attr_reader(:markup_doc)

    after_update :invalidate_markup_cache

    class << self
      def in_project(project)
        where(project_id: project.try(:id) || project)
      end

      def with_markup
        select '*',
               extract_first_node(title_path, 'title'),
               extract_first_node(description_path, 'description'),
               extract_first_node(priority_path, 'priority_text'),
               extract_first_node(status_path, 'status_text'),
               extract_first_node(assignee_path, 'assignee_text'),
               extract_first_node('/Markup/Topic/DueDate/text()', 'due_date_text'),
               extract_first_node('/Markup/Topic/Index/text()', 'index_text'),
               extract_nodes('/Markup/Topic/Labels/text()', 'labels')
      end

      def title_path
        '/Markup/Topic/Title/text()'
      end

      def description_path
        '/Markup/Topic/Description/text()'
      end

      def priority_path
        '/Markup/Topic/Priority/text()'
      end

      def status_path
        '/Markup/Topic/@TopicStatus'
      end

      def assignee_path
        '/Markup/Topic/AssignedTo/text()'
      end

      private

      def extract_first_node(path, as)
        "(xpath('#{path}', markup))[1] AS #{as}"
      end

      def extract_nodes(path, as)
        "(xpath('#{path}', markup)) AS #{as}"
      end
    end

    def title
      if attributes.keys.include? 'title'
        self[:title]
      else
        markup_doc.xpath(self.class.title_path).first.to_s
      end
    end

    def description
      if attributes.keys.include? 'description'
        self[:description]
      else
        markup_doc.xpath(self.class.description_path).first.to_s
      end
    end

    def markup_doc
      @markup_doc ||= Nokogiri::XML markup, nil, 'UTF-8'
    end

    def invalidate_markup_cache
      @markup_doc = nil
    end

    has_many :viewpoints, foreign_key: :issue_id, class_name: "Bcf::Viewpoint"
    has_many :comments, foreign_key: :issue_id, class_name: "Bcf::Comment"
  end
end
