# frozen_string_literal: true

module Cde
  class Container < ApplicationController
    before_action :find_container, except: %i[index new create]
    before_action :authorize_action, only: %i[edit update destroy share publish archive]

    # GET /cde/containers
    def index
      @containers = Cde::Container.includes(:project, :owner, :revisions)
      @containers = @containers.where(project_id: params[:project_id]) if params[:project_id].present?
      @containers = @containers.where(status: params[:status]) if params[:status].present?
      @containers = @containers.search(params[:query]) if params[:query].present?

      render template: 'cde/containers/index'
    end

    # GET /cde/containers/new
    def new
      @container = Cde::Container.new(project: @project)
      render template: 'cde/containers/new'
    end

    # POST /cde/containers
    def create
      @container = Cde::Container.new(container_params.merge(project: @project, owner: current_user))

      if @container.save
        redirect_to cde_container_path(@container), notice: I18n.t('cde.containers.flash.created')
      else
        render template: 'cde/containers/new', status: :unprocessable_entity
      end
    end

    # GET /cde/containers/:id
    def show
      render template: 'cde/containers/show'
    end

    # GET /cde/containers/:id/edit
    def edit
      render template: 'cde/containers/edit'
    end

    # PATCH/PUT /cde/containers/:id
    def update
      if @container.update(container_params)
        redirect_to cde_container_path(@container), notice: I18n.t('cde.containers.flash.updated')
      else
        render template: 'cde/containers/edit', status: :unprocessable_entity
      end
    end

    # DELETE /cde/containers/:id
    def destroy
      @container.destroy
      redirect_to cde_containers_url, notice: I18n.t('cde.containers.flash.deleted')
    end

    # POST /cde/containers/:id/share
    def share
      @container.share!(user: current_user)
      redirect_to cde_container_path(@container), notice: I18n.t('cde.containers.flash.shared')
    end

    # POST /cde/containers/:id/publish
    def publish
      begin
        Cde::PublicationGate.enforce(@container, user: current_user)
        @container.publish!(user: current_user)
        redirect_to cde_container_path(@container), notice: I18n.t('cde.containers.flash.published')
      rescue Cde::PublicationGate::PublicationError => e
        redirect_to cde_container_path(@container), alert: e.message
      end
    end

    # POST /cde/containers/:id/archive
    def archive
      @container.archive!(user: current_user)
      redirect_to cde_containers_url, notice: I18n.t('cde.containers.flash.archived')
    end

    private

    def find_container
      @container = Cde::Container.find_by!(id: params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to cde_containers_url, alert: I18n.t('cde.containers.flash.not_found')
    end

    def authorize_action
      unless current_user.allowed_to?(:edit_container, @container.project)
        raise CanCan::AccessDenied
      end
    end

    def container_params
      params.require(:container).permit(:identifier, :title, :description, :original_filename)
    end

    def @project
      @project ||= Project.find(params[:project_id]) if params[:project_id].present?
      @project ||= current_project
    end
  end
end
