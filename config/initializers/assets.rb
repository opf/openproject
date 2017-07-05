OpenProject::Application.configure do
  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  config.assets.precompile += %w(
    favicon.ico
    openproject.css
    accessibility.css
    accessibility.js
    admin_users.js
    autocompleter.js
    calendar/lang/*.js
    contextual_fieldset.js
    copy_issue_actions.js
    date-de-DE.js
    date-en-US.js
    jstoolbar/lang/*.js
    locales/*.js
    members_form.js
    members_select_boxes.js
    new_user.js
    project/responsible_attribute.js
    repository_navigation.js
    select_list_move.js
    timelines.css
    timelines_modal.js
    timelines_select_boxes.js
    types_checkboxes.js
    work_packages.js
  )
end
