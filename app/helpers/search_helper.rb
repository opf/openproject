#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module SearchHelper
  def highlight_tokens(text, tokens)
    return text unless text && tokens && !tokens.empty?
    re_tokens = tokens.map { |t| Regexp.escape(t) }
    regexp = Regexp.new "(#{re_tokens.join('|')})", Regexp::IGNORECASE
    result = ''
    text.split(regexp).each_with_index do |words, i|
      if result.length > 1200
        # maximum length of the preview reached
        result << '...'
        break
      end
      if i.even?
        result << h(words.length > 100 ? "#{words.slice(0..44)} ... #{words.slice(-45..-1)}" : words)
      else
        t = (tokens.index(words.downcase) || 0) % 4
        result << content_tag('span', h(words), class: "highlight token-#{t}")
      end
    end
    result.html_safe
  end

  def highlight_first(texts, tokens)
    texts.each do |text|
      if has_tokens? text, tokens
        return highlight_tokens text, tokens
      end
    end
    highlight_tokens texts[-1], tokens
  end

  def has_tokens?(text, tokens)
    return false unless text && tokens && !tokens.empty?
    re_tokens = tokens.map { |t| Regexp.escape(t) }
    regexp = Regexp.new "(#{re_tokens.join('|')})", Regexp::IGNORECASE
    !!regexp.match(text)
  end

  def last_journal(event)
    if event.respond_to? :last_journal
      event.last_loaded_journal
    end
  end

  def notes_anchor(event)
    version = event.version.to_i

    (version > 1) ? "note-#{version - 1}" : ''
  end

  def with_notes_anchor(event, tokens)
    if has_tokens? last_journal(event).try(:notes), tokens
      event.event_url.merge anchor: notes_anchor(last_journal event)
    else
      event.event_url
    end
  end

  def type_label(t)
    l("label_#{t.singularize}_plural", default: t.to_s.humanize)
  end

  def project_select_tag
    options = [[l(:label_project_all), 'all']]
    options << [l(:label_my_projects), 'my_projects'] unless User.current.memberships.empty?
    options << [l(:label_and_its_subprojects, @project.name), 'subprojects'] unless @project.nil? || @project.descendants.active.empty?
    options << [@project.name, 'current_project'] unless @project.nil?
    styled_select_tag('scope', options_for_select(options, current_scope)) if options.size > 1
  end

  def render_results_by_type(results_by_type)
    links = []
    # Sorts types by results count
    results_by_type.keys.sort { |a, b| results_by_type[b] <=> results_by_type[a] }.each do |t|
      c = results_by_type[t]
      next if c == 0
      text = "#{type_label(t)} (#{c})"
      target = {
        controller: 'search',
        project_id: (@project.identifier if @project),
        action: 'index',
        q: params[:q],
        titles_only: params[:title_only],
        all_words: params[:all_words],
        scope: current_scope,
        t => 1
      }
      links << link_to(h(text), target)
    end
    ('<ul>' + links.map { |link| content_tag('li', link) }.join(' ') + '</ul>').html_safe unless links.empty?
  end

  def current_scope
    params[:scope] || ('current_project' unless @project.nil?)
  end

  def link_to_previous_search_page(pagination_previous_date)
    link_to_content_update(l(:label_previous),
                           params.merge(previous: 1, offset: pagination_previous_date.to_r.to_s), class: 'navigate-left')
  end

  def link_to_next_search_page(pagination_next_date)
    link_to_content_update(l(:label_next),
                           params.merge(previous: nil, offset: pagination_next_date.to_r.to_s), class: 'navigate-right')
  end
end
