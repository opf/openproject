module Bcf
  class Issue < ActiveRecord::Base
    include InitializeWithUuid

    belongs_to :work_package
    belongs_to :project

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
               extract_first_node(type_path, 'type_text'),
               extract_first_node(assignee_path, 'assignee_text'),
               extract_first_node(due_date_path, 'due_date_text'),
               extract_first_node(index_path, 'index_text'),
               extract_nodes(labels_path, 'labels')
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

      def type_path
        '/Markup/Topic/@TopicType'
      end

      def assignee_path
        '/Markup/Topic/AssignedTo/text()'
      end

      def due_date_path
        '/Markup/Topic/DueDate/text()'
      end

      def index_path
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

    def title
      if attributes.keys.include? 'title'
        self[:title]
      else
        markup_doc.xpath(self.class.title_path).first.to_s.presence
      end
    end

    def description
      if attributes.keys.include? 'description'
        self[:description]
      else
        markup_doc.xpath(self.class.description_path).first.to_s.presence
      end
    end

    def priority_text
      if attributes.keys.include? 'priority_text'
        self[:priority_text]
      else
        markup_doc.xpath(self.class.priority_path).first.to_s.presence
      end
    end

    def status_text
      if attributes.keys.include? 'status_text'
        self[:status_text]
      else
        markup_doc.xpath(self.class.status_path).first.to_s.presence
      end
    end

    def type_text
      if attributes.keys.include? 'type_text'
        self[:type_text]
      else
        markup_doc.xpath(self.class.type_path).first.to_s.presence
      end
    end

    def assignee_text
      if attributes.keys.include? 'assignee_text'
        self[:assignee_text]
      else
        markup_doc.xpath(self.class.assignee_path).first.to_s.presence
      end
    end

    def due_date_text
      if attributes.keys.include? 'due_date_text'
        self[:due_date_text]
      else
        markup_doc.xpath(self.class.due_date_path).first.to_s.presence
      end
    end

    def index_text
      if attributes.keys.include? 'index_text'
        self[:index_text]
      else
        markup_doc.xpath(self.class.index_path).first.to_s.presence
      end
    end

    def labels
      if attributes.keys.include? 'labels'
        self[:labels]
      else
        markup_doc.xpath(self.class.labels_path).map(&:to_s)
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
