# frozen_string_literal: true

# Hides Wiki, News, Documents and Meetings from menus without removing any code.
# To re-enable a module, comment out its block below and restart the server.

Rails.application.config.after_initialize do
  # Load our custom translations last so they override Crowdin files
  I18n.backend.store_translations(:'pt-BR', YAML.load_file(
    Rails.root.join("config/locales/mngt.pt-BR.yml")
  ).dig("pt-BR").transform_keys(&:to_sym))


  # --- News -------------------------------------------------------------------
  # Registered in top_menu, my_menu, global_menu and project_menu
  Redmine::MenuManager.map(:top_menu)     { |m| m.delete(:news) }
  Redmine::MenuManager.map(:my_menu)      { |m| m.delete(:news) }
  Redmine::MenuManager.map(:global_menu)  { |m| m.delete(:news) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:news) }

  # --- Documents --------------------------------------------------------------
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:documents) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:documents_sub_menu) }

  # --- Meetings ---------------------------------------------------------------
  # Registered in top_menu, global_menu and project_menu
  Redmine::MenuManager.map(:top_menu)     { |m| m.delete(:meetings) }
  Redmine::MenuManager.map(:global_menu)  { |m| m.delete(:meetings) }
  Redmine::MenuManager.map(:global_menu)  { |m| m.delete(:meetings_query_select) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:meetings) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:meetings_query_select) }

  # --- BCF (BIM Collaboration Format) ----------------------------------------
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:ifc_models) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:ifc_viewer_panels) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:revit_add_in) }

  # --- Calendários ------------------------------------------------------------
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:calendar_view) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:calendar_menu) }

  # --- Planejador de equipe ---------------------------------------------------
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:team_planner_view) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:team_planner_menu) }

  # --- Backlogs ---------------------------------------------------------------
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:backlogs) }
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:backlog) }

  # --- Fóruns -----------------------------------------------------------------
  Redmine::MenuManager.map(:project_menu) { |m| m.delete(:forums) }

  # --- Wiki -------------------------------------------------------------------
  # Wiki items are added dynamically per request; prepend makes build_wiki_menus
  # a no-op so nothing is pushed to the project sidebar.
  Redmine::MenuManager::WikiMenuHelper.prepend(Module.new do
    def build_wiki_menus(_project) = nil
  end)
end
