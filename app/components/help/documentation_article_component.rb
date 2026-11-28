# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Help
  class DocumentationArticleComponent < ApplicationComponent
    def initialize(article_id:, context: "life_cycle")
      super()
      @context = context
      @articles = DocumentationArticle.for_context(context)
      @article = DocumentationArticle.new(article_id) unless article_id == "index"
    end

    def body
      helpers.sanitize(document.to_html,
                       attributes: %w[href src alt title width height id class target rel loading scope
                                      data-help-article data-turbo-frame])
    end

    def headings
      document.css("h2, h3")
    end

    private

    def document
      @document ||= Nokogiri::HTML5.fragment(@article.html).tap do |doc|
        doc.at_css("h1")&.remove
        doc.css("h2, h3, h4").each_with_index { |heading, i| heading["id"] = "help-section-#{i}" }
        rewrite_links(doc)
        rewrite_images(doc)
      end
    end

    def rewrite_links(doc)
      doc.css("a[href]").each { |link| rewrite_link(link) }
    end

    def rewrite_link(link)
      if (article = @article.linked_article(link["href"]))
        link["href"] = documentation_article_help_path(article_id: article.id, context: @context)
        link["data-help-article"] = "true"
      else
        link["href"] = URI.join(@article.url, link["href"]).to_s
        link["target"] = "_blank"
        link["rel"] = "noopener noreferrer"
      end
    rescue URI::InvalidURIError
      link.remove_attribute("href")
    end

    def rewrite_images(doc)
      doc.css("img[src]").each do |image|
        filename = image["src"]
        @article.asset_path(filename)
        image["src"] = documentation_asset_help_path(article_id: @article.id, filename:)
        image["loading"] = "lazy"
      rescue KeyError
        image["src"] = URI.join(@article.url, filename).to_s
      end
    end
  end
end
