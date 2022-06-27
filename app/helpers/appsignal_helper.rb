module AppsignalHelper
  def appsignal_frontend_tag
    return '' unless OpenProject::Configuration.appsignal_frontend_key

    tag :meta,
        name: 'openproject_appsignal',
        data: {
          push_key: OpenProject::Configuration.appsignal_frontend_key,
          version: OpenProject::VERSION.to_s
        }
  end
end
