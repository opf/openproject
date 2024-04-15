Rails.application.configure do
  config.view_component.generate.preview_path = Rails.root.join("spec/components/previews").to_s
  config.view_component.preview_paths << Rails.root.join("spec/components/previews").to_s

  config.view_component.generate.preview = true
  config.view_component.default_preview_layout = "component_preview"
end
