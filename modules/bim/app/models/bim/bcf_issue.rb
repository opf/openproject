module Bim
  class BcfIssue < ActiveRecord::Base
    include InitializeWithUuid

    belongs_to :work_package
    belongs_to :project

    class << self
      def in_project(project)
        where(project_id: project.try(:id) || project)
      end

      def with_markup
        select '*',
               extract_xml('/Markup/Topic/Title/text()', 'title'),
               extract_xml('/Markup/Topic/Description/text()', 'description'),
               extract_xml('/Markup/Topic/Priority/text()', 'priority_text'),
               extract_xml('/Markup/Topic/@TopicStatus', 'status_text')
      end

      private

      def extract_xml(path, as)
        "(xpath('#{path}', markup))[1] AS #{as}"
      end
    end

    has_many :viewpoints, foreign_key: :issue_id, class_name: "Bim::BcfViewpoint"
    has_many :comments, foreign_key: :issue_id, class_name: "Bim::BcfComment"
  end
end
