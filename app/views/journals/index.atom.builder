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

xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title   title
  xml.link    "rel" => "self", "href" => url_for(:format => 'atom', :key => User.current.rss_key, :only_path => false)
  xml.link    "rel" => "alternate", "href" => home_url(:only_path => false)
  xml.id      url_for(:controller => '/welcome', :only_path => false)
  xml.updated((journals.first ? journals.first.created_at : Time.now).xmlschema)
  xml.author  { xml.name "#{Setting.app_title}" }
  journals.each do |change|
    work_package = change.journable
    xml.entry do
      xml.title   "#{work_package.project.name} - #{work_package.type.name} ##{work_package.id}: #{work_package.subject}"
      xml.link    "rel" => "alternate", "href" => work_package_url(work_package)
      xml.id      url_for(:controller => '/work_packages' , :action => 'show', :id => work_package, :journal_id => change, :only_path => false)
      xml.updated change.created_at.xmlschema
      xml.author do
        xml.name change.user.name
        xml.email(change.user.mail) if change.user.is_a?(User) && !change.user.mail.blank? && !change.user.pref.hide_mail
      end
      xml.content "type" => "html" do
        xml.text! '<ul>'
        change.changed_data.each do |detail|
          change_content = change.render_detail(detail, :no_html => false)
          xml.text!(content_tag(:li, change_content)) if change_content.present?
        end
        xml.text! '</ul>'
        xml.text! format_text(change, :notes, :only_path => false) unless change.notes.blank?
      end
    end
  end
end
