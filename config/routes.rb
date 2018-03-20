#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

# re-write
OpenProject::Application.routes.draw do
  # replace the standard overview-page with the my-project-page
  # careful: do not over-match the reserved path like /projects/new or /projects/level_list, see http://rubular.com/r/1uoiXyApCB
  get 'projects/:id', to: "my_projects_overviews#index" ,
                      constraints: { format: :html, id: Regexp.new("(?!(#{Project::RESERVED_IDENTIFIERS.join('|')})$)(\\w|-)+") }




  get  'my_projects_overview/:id/page_layout',                        to: "my_projects_overviews#page_layout",
                                                                      as: :my_projects_overview
  post 'my_projects_overview/:id/page_layout/save_changes',           to: "my_projects_overviews#save_changes"
  post 'my_projects_overview/:id/page_layout/add_block',              to: "my_projects_overviews#add_block"
  put  'my_projects_overview/:id/page_layout/update_custom_element',  to: "my_projects_overviews#update_custom_element"
  get  'my_projects_overview/:id/page_layout/render_attachments',     to: "my_projects_overviews#render_attachments"
  post 'my_projects_overview/:id/page_layout/destroy_attachment',     to: "my_projects_overviews#destroy_attachment"
end
