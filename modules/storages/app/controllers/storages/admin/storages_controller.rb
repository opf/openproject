#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

# Purpose: CRUD the global admin page of Storages (=Nextcloud servers)
# ToDo: Why not use double "module"
# ToDo: What Wieland already explained ::Module vs. Module (without ::)
class Storages::Admin::StoragesController < ApplicationController
  # ToDo: Where is this used?
  # I assume this will create a page layout for a global OpenProject admin page
  layout 'admin'

  # I assume this is necessary because of the non-standard path of this controller?
  model_object Storages::Storage

  # Before executing any action below: Make sure the current user is an admin
  # and set the @<controller_name> variable to the object refernced in the URL.???
  before_action :require_admin
  before_action :find_model_object, only: %i[show destroy edit update]

  # ToDo: Where is this used?
  # I understand this will create(???) a menu item in Admin to Storages
  menu_item :storages_admin_settings

  # Index page with a list of Storages objects
  # Called by: Global app/config/routes.rb to serve Web page
  def index
    @storages = Storages::Storage.all

    # The view is located in a slightly off-standard directory
    # Why not use a leading "/" as in other places?
    render 'storages/admin/index'
  end

  # Show page with details of one Storage object.
  # Called by: Global app/config/routes.rb to serve Web page
  def show
    render 'storages/admin/show'
  end

  # Show the admin page to create a new Storage object.
  # Sets the attributes provider_type and name for the service(???)
  # as default values and then renders the new page (allowing the user
  # to overwrite these values and to fill in other attributes).
  # Used by: The index page above, when the user presses the (+) button.
  # Called by: Global app/config/routes.rb to serve Web page
  def new
    # Set default parameters using a "service".
    # See also: storages/services/storages/storages/set_attributes_services.rb
    # See also: ToDo: Service documentation from Wieland
    # That service inherits from ::BaseServices::SetAttributes
    # ToDo: I don't understand where call(...) is defined, and what this
    # service actually does.
    @object = ::Storages::Storages::SetAttributesService
                .new(user: current_user,
                     model: Storages::Storage.new,
                     contract_class: EmptyContract)
                .call({ provider_type: 'nextcloud', name: I18n.t('storages.provider_types.nextcloud') })
                .result
    # What about error processing in case the service returns nil???

    # Render the new page in a slightly off-standard location
    render 'storages/admin/new'
  end

  # ToDo: RuboCop: Metrics/AbcSize: Assignment Branch Condition size for create is too high. [<7, 21, 2> 22.23/17]
  # ToDo: Move the comments back into the method
  # Actually create a Storage object.
  # Overwrite the creator_id with the current_user. Is this this pattern always used?
  # Use service pattern to create a new Storage
  # See also: storages/services/storages/storages/create_service.rb
  # storage_path is automagically created by Ruby controller for the Storage object.
  # Just render a response to (un-)successful creation.
  # respond_to takes a URL parameter about the format. Only HTML is supported here.
  # Called by: Global app/config/routes.rb to serve Web page
  # rubocop:disable Metrics/AbcSize
  def create
    combined_params = permitted_storage_params.to_h.reverse_merge(creator_id: current_user.id)
    service_result = Storages::Storages::CreateService.new(user: current_user).call(combined_params)
    @object = service_result.result

    if service_result.success?
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_create)
          redirect_to storage_path(@object)
        end
      end
    else
      @errors = service_result.errors
      respond_to do |format|
        format.html do
          render 'storages/admin/new'
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  # Edit page is very similar to new page, except that we don't need to set
  # default attribute values because the object already exists
  # Called by: Global app/config/routes.rb to serve Web page
  def edit
    render 'storages/admin/edit'
  end

  # Update is similar to create above
  # Also see: create above
  # Called by: Global app/config/routes.rb to serve Web page
  def update
    # ToDo: Multi-line call to service instead of one-line above
    service_result = ::Storages::Storages::UpdateService
                       .new(user: current_user,
                            model: @object)
                       .call(permitted_storage_params)

    if service_result.success?
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to storage_path(@object)
        end
      end
    else
      respond_to do |format|
        format.html do
          render action: :edit
        end
      end
    end
  end

  # Purpose: Destroy a specific Storage
  # Called by: Global app/config/routes.rb to serve Web page
  def destroy
    Storages::Storages::DeleteService
      .new(user: User.current, model: @object)
      .call

    # ToDo: Where is "flash" defined
    # Displays a message box on the next page
    flash[:info] = I18n.t(:notice_successful_delete)

    # Redirect to the index page
    respond_to do |format|
      format.html do
        redirect_to storages_path
      end
    end
  end

  # Used by: ToDo:
  # Breadcrumbs is something like OpenProject > Admin > Storages.
  # This returns the name of the last part (Storages admin page)
  def default_breadcrumb
    if action_name == :index
      t(:project_module_storages)
    else
      ActionController::Base.helpers.link_to(t(:project_module_storages), storages_path)
    end
  end

  # See: default_breadcrum above
  # Defines whether to show breadcrumbs on the page or not.
  def show_local_breadcrumb
    true
  end

  private

  # Called by create and update above in order to check if the
  # update parameters are correctly set.
  def permitted_storage_params
    # ToDo: How does :storages_storage work? Isn't this "id"? Who transforms?
    params
      .require(:storages_storage)
      .permit('name', 'provider_type', 'host')
  end
end
