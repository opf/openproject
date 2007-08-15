# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

require 'coderay'
require 'coderay/helpers/file_type'

module RepositoriesHelper
  def syntax_highlight(name, content)
    type = CodeRay::FileType[name]
    type ? CodeRay.scan(content, type).html : h(content)
  end
    
  def repository_field_tags(form, repository)    
    method = repository.class.name.demodulize.underscore + "_field_tags"
    send(method, form, repository) if repository.is_a?(Repository) && respond_to?(method)
  end
  
  def scm_select_tag
    container = [[]]
    REDMINE_SUPPORTED_SCM.each {|scm| container << ["Repository::#{scm}".constantize.scm_name, scm]}
    select_tag('repository_scm', 
               options_for_select(container, @project.repository.class.name.demodulize),
               :disabled => (@project.repository && !@project.repository.new_record?),
               :onchange => remote_function(:update => "repository_fields", :url => { :controller => 'repositories', :action => 'update_form', :id => @project }, :with => "Form.serialize(this.form)")
               )
  end
  
  def with_leading_slash(path)
    path ||= ''
    path.starts_with?("/") ? "/#{path}" : path
  end

  def subversion_field_tags(form, repository)
      content_tag('p', form.text_field(:url, :size => 60, :required => true, :disabled => (repository && !repository.root_url.blank?)) +
                       '<br />(http://, https://, svn://, file:///)') +
      content_tag('p', form.text_field(:login, :size => 30)) +
      content_tag('p', form.password_field(:password, :size => 30))
  end

  def darcs_field_tags(form, repository)
      content_tag('p', form.text_field(:url, :label => 'Root directory', :size => 60, :required => true, :disabled => (repository && !repository.new_record?)))
  end
  
  def mercurial_field_tags(form, repository)
      content_tag('p', form.text_field(:url, :label => 'Root directory', :size => 60, :required => true, :disabled => (repository && !repository.root_url.blank?)))
  end

  def cvs_field_tags(form, repository)
      content_tag('p', form.text_field(:root_url, :label => 'CVSROOT', :size => 60, :required => true, :disabled => !repository.new_record?)) +
      content_tag('p', form.text_field(:url, :label => 'Module', :size => 30, :required => true, :disabled => !repository.new_record?))
  end
end
