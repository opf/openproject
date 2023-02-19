class AddPolymorphicIntegrationToOAuthApplication < ActiveRecord::Migration[7.0]
  def change
    add_reference :oauth_applications, :integration, polymorphic: true
  end
end
