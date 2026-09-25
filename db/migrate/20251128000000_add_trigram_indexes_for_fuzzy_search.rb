# frozen_string_literal: true

class AddTrigramIndexesForFuzzySearch < ActiveRecord::Migration[8.0]
  def change
    # Projects: name, identifier, description
    add_index :projects, :name,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_projects_on_name_trigram"
    add_index :projects, :identifier,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_projects_on_identifier_trigram"
    add_index :projects, :description,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_projects_on_description_trigram"

    # Work packages: subject, description
    add_index :work_packages, :subject,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_work_packages_on_subject_trigram"
    add_index :work_packages, :description,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_work_packages_on_description_trigram"

    # News: title, summary, description
    add_index :news, :title,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_news_on_title_trigram"
    add_index :news, :summary,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_news_on_summary_trigram"
    add_index :news, :description,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_news_on_description_trigram"

    # Wiki pages: title and text (text column is on wiki_pages table)
    add_index :wiki_pages, :title,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_wiki_pages_on_title_trigram"
    add_index :wiki_pages, :text,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_wiki_pages_on_text_trigram"

    # Messages: subject, content
    add_index :messages, :subject,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_messages_on_subject_trigram"
    add_index :messages, :content,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_messages_on_content_trigram"

    # Changesets: comments
    add_index :changesets, :comments,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_changesets_on_comments_trigram"

    # Documents: title, description
    add_index :documents, :title,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_documents_on_title_trigram"
    add_index :documents, :description,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_documents_on_description_trigram"

    # Meetings: title
    add_index :meetings, :title,
              using: "gin",
              opclass: :gin_trgm_ops,
              name: "index_meetings_on_title_trigram"
  end
end

