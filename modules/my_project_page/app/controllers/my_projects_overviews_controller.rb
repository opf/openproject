#-- encoding: UTF-8
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

class MyProjectsOverviewsController < ApplicationController
  menu_item :overview

  before_action :find_project
  before_action :authorize
  before_action :jump_to_project_menu_item, only: :index

  def self.available_blocks
    @available_blocks ||= OpenProject::MyProjectPage.plugin_blocks
  end

  def index; end

  # User's page layout configuration
  def page_layout; end

  def update_custom_element
    block_name = params["block_name"]
    block_title = params["block_title_#{block_name}"]
    textile = params["textile_#{block_name}"]
    attaching_files = params['attachments']

    if attaching_files
      # Attach files and save them
      overview.attach_files(permitted_params.attachments.to_h)
    end

    if overview.save_custom_element(block_name, block_title, textile)
      render_attachment_warning_if_needed(overview) if attaching_files
      render(partial: "block_textilizable",
             locals: { project: project,
                       block_title: block_title,
                       block_name: block_name,
                       textile: textile })
    else
      render plain: t(:error_block_not_saved), status: 400
    end
  end

  # Add a block to user's page
  # The block is added on top of the page
  # params[:block] : id of the block to add
  def add_block
    block = params[:block]
    if MyProjectsOverviewsController.available_blocks.keys.include? block
      render partial: "block", locals: { block_name: block, edit: true }
    elsif block == "custom_element"
      render_new_custom_block
    else
      head :ok
    end
  end

  ##
  # Handle saving the changes
  def save_changes
    # Save block states
    save_blocks_from_params

    if overview.save
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to(action: :index)
    else
      flash[:error] = I18n.t(:error_saving_changes,
                             errors: overview.errors.full_messages.join(', '))
      render :page_layout
    end
  end

  helper_method :project,
                :user,
                :overview
  def project
    @project
  end

  def user
    current_user
  end

  def overview
    @overview ||= MyProjectsOverview.find_or_create_by(project_id: project.id)
  end

  private

  def render_new_custom_block
    new_block = overview.new_custom_element
    overview.hidden << new_block
    if overview.save
      render(partial: "block_textilizable",
             locals: { project: project,
                       block_title: l(:label_custom_element),
                       new_block: true,
                       block_name: new_block.first,
                       textile: new_block.last })
    else
      render plain: I18n.t(:error_saving_changes, errors: overview.errors.full_messages.join(', ')),
                    status: 500
    end
  end

  ##
  # Given params of the form
  # { top: 'block,block,block', ... }
  # Save the actual block positions, filtering the list doing so.
  def save_blocks_from_params
    custom_elements = overview.custom_elements

    %w(top left right hidden).each do |group|
      active_blocks = param_to_blocks(params[group], custom_elements)
      overview.send("#{group}=", active_blocks)
    end
  end

  ##
  # Returns a list of valid blocks for the given group param
  def param_to_blocks(block_str, custom_elements)
    blocks = []
    block_str.split(',').select do |name|
      if MyProjectsOverviewsController.available_blocks.keys.include?(name)
        blocks << name
      else
        custom = custom_elements.detect { |ary| ary.first == name }
        blocks << custom unless custom.nil?
      end
    end

    blocks
  end

  def default_breadcrumb
    l(:label_overview)
  end

  def jump_to_project_menu_item
    if params[:jump]
      # try to redirect to the requested menu item
      redirect_to_project_menu_item(project, params[:jump]) && return
    end
  end
end
