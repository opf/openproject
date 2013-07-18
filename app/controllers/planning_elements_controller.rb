#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class PlanningElementsController < ApplicationController
  unloadable
  helper :timelines, :planning_elements

  include ExtendedHTTP

  menu_item :planning_elements
  menu_item :recycle_bin, :only => [:move_to_trash, :confirm_move_to_trash,
                                    :recycle_bin, :destroy_all, :confirm_destroy_all,
                                    :restore_all, :confirm_restore_all]

  before_filter :disable_api
  before_filter :find_project_by_project_id,
                :authorize,
                :assign_planning_elements, :except => [:index, :list]
  before_filter :apply_at_timestamp, :only => [:show]

  # Attention: find_all_projects_by_project_id needs to mimic all of the above
  #            before filters !!!
  before_filter :find_all_projects_by_project_id, :only => :index

  helper :timelines
  helper :timelines_journals

  accept_key_auth :index, :create, :show, :update, :destroy, :list

  def index
    optimize_planning_elements_for_less_db_queries

    respond_to do |format|
      format.html
    end
  end

  def all
    respond_to do |format|
      format.html { render :action => 'index' }
    end
  end

  def recycle_bin
    @planning_elements = @project.planning_elements.deleted
    respond_to do |format|
      format.html
    end
  end

  def new
    @planning_element = @planning_elements.build()

    respond_to do |format|
      format.html
      format.js   { render :partial => 'new' }
    end
  end

  def create
    @planning_element = @planning_elements.new(permitted_params.planning_element)
    successfully_created = @planning_element.save

    respond_to do |format|

      format.html do
        if successfully_created
          flash[:notice] = l(:notice_successful_create)
          redirect_to project_planning_element_path(@project, @planning_element)
        else
          flash.now[:error] = l('timelines.planning_element_could_not_be_saved')
          render :action => "new"
        end
      end
    end
  end

  def show
    @planning_element = @project.planning_elements.find(params[:id])

    respond_to do |format|
      format.html
      format.js { render :partial => 'show'}
    end
  end

  def edit
    @planning_element = @planning_elements.find(params[:id])

    respond_to do |format|
      format.html
      format.js   { render :partial => 'edit' }
    end
  end

  def update
    @planning_element = @planning_elements.find(params[:id])
    @planning_element.attributes = permitted_params.planning_element

    successfully_updated = @planning_element.save

    respond_to do |format|
      format.html do
        if successfully_updated
          flash[:notice] = l(:notice_successful_update)
          redirect_to project_planning_element_path(@project, @planning_element)
        else
          flash.now[:error] = l('timelines.planning_element_could_not_be_saved')
          render :action => "edit"
        end
      end
    end
  end

  def list
    options = {:order => 'id'}

    projects = Project.visible.select do |project|
      User.current.allowed_to?(:view_planning_elements, project)
    end

    if params[:ids]
      ids = params[:ids].split(/,/).map(&:strip).select { |s| s =~ /^\d*$/ }.map(&:to_i).sort
      project_ids = projects.map(&:id).sort
      options[:conditions] = ["id IN (?) AND project_id IN (?)", ids, project_ids]
    end

    @planning_elements = PlanningElement.all(options)

    respond_to do |format|
      format.html { render :action => :index }
    end
  end

  def confirm_move_to_trash
    @planning_element = @planning_elements.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def confirm_destroy
    @planning_element = @project.planning_elements.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def destroy
    @planning_element = @project.planning_elements.find(params[:id])
    @planning_element.destroy

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_to project_planning_elements_path(@project)
      end
    end
  end

  def confirm_destroy_all
    @planning_elements = @project.planning_elements.deleted

    respond_to do |format|
      format.html
    end
  end

  def destroy_all
    @project.planning_elements.deleted.each do |element|
      element.destroy
    end

    flash[:notice] = l("timelines.notice_successful_deleted_all_elements")
    redirect_to(recycle_bin_project_planning_elements_path(@project))
  end

  def move_to_trash
    @planning_element = @planning_elements.find(params[:id])
    @planning_element.trash

    respond_to do |format|
      format.html do
        flash[:notice] = l("timelines.notice_successful_moved_to_trash")
        redirect_to project_planning_elements_path(@project)
      end
    end
  end

  def restore
    @planning_element = @project.planning_elements.find(params[:id])
    successfully_restored = @planning_element.restore!

    respond_to do |format|
      format.html do
        if successfully_restored
          flash[:notice] = l("timelines.notice_successful_restored")
        else
          flash.now[:error] = l('timelines.planning_element_could_not_be_restored')
        end

        redirect_to(recycle_bin_project_planning_elements_path(@project))
      end
    end
  end

  def confirm_restore_all
    @planning_elements = @project.planning_elements.deleted

    respond_to do |format|
      format.html
    end
  end

  def restore_all
    @project.planning_elements.deleted.each do |element|
      element.restore!
    end

    flash[:notice] = l("timelines.notice_successful_restored_all_elements")
    redirect_to(recycle_bin_project_planning_elements_path(@project))
  end

  protected

  # Filters
  def find_all_projects_by_project_id
    if params[:format] == 'html' or params[:project_id] !~ /,/
      find_project_by_project_id unless performed?
      authorize                  unless performed?
      assign_planning_elements   unless performed?
      apply_at_timestamp         unless performed?
    else
      # find_project_by_project_id
      ids, identifiers = params[:project_id].split(/,/).map(&:strip).partition { |s| s =~ /^\d*$/ }
      ids = ids.map(&:to_i).sort
      identifiers = identifiers.sort

      @projects = []
      @projects |= Project.all(:conditions => {:id => ids}) unless ids.empty?
      @projects |= Project.all(:conditions => {:identifier => identifiers}) unless identifiers.empty?

      if (@projects.map(&:id) & ids).size != ids.size ||
         (@projects.map(&:identifier) & identifiers).size != identifiers.size
        # => not all projects could be found
        render_404
        return
      end

      # authorize
      # Ignoring projects, where user has no view_planning_elements permission.
      @projects = @projects.select do |project|
        User.current.allowed_to?({:controller => params[:controller],
                                  :action     => params[:action]},
                                 project)
      end

      if @projects.blank?
        @planning_elements = []
        return
      end

      # assign_planning_elements and apply_at_timestamp
      if params[:at].blank?
        @planning_elements = PlanningElement.for_projects(@projects).without_deleted
      else
        begin
          time = Time.at(Integer(params[:at]))
          # intentionally avoiding without_deleted scope
          @planning_elements = PlanningElement.for_projects(@projects).at_time(time)
        rescue ArgumentError
          render_errors(:at => 'unknown format')
        end
      end
    end
  end

  def assign_planning_elements
    @planning_elements = @project.planning_elements.without_deleted
  end

  def apply_at_timestamp
    return if params[:at].blank?

    time = Time.at(Integer(params[:at]))
    # intentionally rebuilding scope chain to avoid without_deleted scope
    @planning_elements = @project.planning_elements.at_time(time)

  rescue ArgumentError
    render_errors(:at => 'unknown format')
  end

  # Helpers
  helper_method :include_journals?, :include_scenarios?

  def include_journals?
    params[:include].tap { |i| i.present? && i.include?("journals") }
  end

  def include_scenarios?
    !params[:exclude].tap { |i| i.present? && i.include?("scenarios") }
  end


  def default_breadcrumb
    l('timelines.project_menu.planning_elements')
  end

  # Actual protected methods
  def render_errors(errors)
    options = {:status => :bad_request, :layout => false}
    options.merge!(case params[:format]
      when 'xml';  {:xml => errors}
      when 'json'; {:json => {'errors' => errors}}
      else
        raise "Unknown format #{params[:format]} in #render_validation_errors"
      end
    )
    render options
  end

  def optimize_planning_elements_for_less_db_queries
    # abort if @planning_elements is already an array, using .class check since
    # .is_a? acts weird on named scopes
    return if @planning_elements.class == Array

    # triggering full load to avoid separate queries for count or related models
    @planning_elements = @planning_elements.all(:include => [:planning_element_type, :project])

    # Replacing association proxies with already loaded instances to avoid
    # further db calls.
    #
    # This assumes, that all planning elements within a project where loaded
    # and that parent-child relations may only occur within a project.
    #
    # It is also dependent on implementation details of ActiveRecord::Base,
    # so it might break in later versions of Rails.
    #
    # See association_instance_get/_set in ActiveRecord::Associations


    ids_hash      = @planning_elements.inject({}) { |h, pe| h[pe.id] = pe; h }
    children_hash = Hash.new { |h,k| h[k] = [] }

    parent_refl, children_refl = [:parent, :children].map{|assoc| PlanningElement.reflect_on_association(assoc)}

    associations = {
      :belongs_to => ActiveRecord::Associations::BelongsToAssociation,
      :has_many => ActiveRecord::Associations::HasManyAssociation
    }

    # 'caching' already loaded parent and children associations
    @planning_elements.each do |pe|
      children_hash[pe.parent_id] << pe

      parent = nil
      if ids_hash.has_key? pe.parent_id
        parent = associations[parent_refl.macro].new(pe, parent_refl)
        parent.target = ids_hash[pe.parent_id]
      end
      pe.send(:association_instance_set, :parent, parent)

      children = associations[children_refl.macro].new(pe, children_refl)
      children.target = children_hash[pe.id]
      pe.send(:association_instance_set, :children, children)
    end
  end
end
