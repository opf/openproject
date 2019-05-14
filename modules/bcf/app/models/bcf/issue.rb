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
               extract_first_node('/Markup/Topic/Title/text()', 'title'),
               extract_first_node('/Markup/Topic/Description/text()', 'description'),
               extract_first_node('/Markup/Topic/Priority/text()', 'priority_text'),
               extract_first_node('/Markup/Topic/@TopicStatus', 'status_text'),
               extract_first_node('/Markup/Topic/AssignedTo/text()', 'assignee_text'),
               extract_first_node('/Markup/Topic/DueDate/text()', 'due_date_text'),
               extract_first_node('/Markup/Topic/Index/text()', 'index_text'),
               extract_nodes('/Markup/Topic/Labels/text()', 'labels')
      end

      private

      def extract_first_node(path, as)
        "(xpath('#{path}', markup))[1] AS #{as}"
      end

      def extract_nodes(path, as)
        "(xpath('#{path}', markup)) AS #{as}"
      end
    end

    def markup_doc
      @markup_doc ||= Nokogiri::XML markup
    end

    def invalidate_markup_cache
      @markup_doc = nil
    end

    has_many :viewpoints, foreign_key: :issue_id, class_name: "Bcf::Viewpoint"
    has_many :comments, foreign_key: :issue_id, class_name: "Bcf::Comment"
  end
end
