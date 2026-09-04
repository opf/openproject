# Slice 10: Security & Authentication Enhancement - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 10 (Cross-cutting concern)
**Dependencies:** All slices (applies security globally)

---

## Current State Analysis

### Existing Capabilities (Community Edition)
✅ **Basic Authentication**: Username/password
✅ **LDAP**: Available via plugin
✅ **Role-Based Access**: Standard OpenProject permissions
❌ **No 2FA** (only in Enterprise)
❌ **No SSO** (limited support)

---

## Enterprise Enhancement Goals

### 1. Pluggable Authentication Adapters
- **Interface-Based Design**: AuthenticationAdapter interface
- **Optional Extensions**: SSO, LDAP, 2FA as optional plugins
- **Backward Compatibility**: Keep existing auth working

### 2. Enhanced Permissions
- **BIM-Specific Permissions**:
  - `view_bim_models`
  - `upload_bim_models`
  - `run_clash_detection`
  - `manage_bim_baselines`
- **Element-Level Permissions**: Restrict by discipline/zone
- **API Key Management**: For external integrations (Revit, etc.)

### 3. Audit Logging
- **Track BIM Actions**: Model uploads, clash runs, baseline changes
- **Compliance**: GDPR, SOC2 audit trails

---

## Proposed Architecture

### Layer 1: Authentication Adapter Pattern

```ruby
# New: modules/bim/lib/bim/authentication/adapter.rb
module Bim
  module Authentication
    class Adapter
      # Abstract interface for authentication adapters
      def authenticate(credentials)
        raise NotImplementedError
      end

      def supports_2fa?
        false
      end

      def enabled?
        true
      end
    end

    # Built-in adapter
    class DatabaseAdapter < Adapter
      def authenticate(credentials)
        User.authenticate(credentials[:username], credentials[:password])
      end
    end

    # Optional SSO adapter (disabled by default)
    class SSOAdapter < Adapter
      def enabled?
        ENV['BIM_SSO_ENABLED'] == 'true'
      end

      def authenticate(saml_response)
        # SAML/OAuth2 authentication
      end
    end

    # Optional LDAP adapter
    class LDAPAdapter < Adapter
      def enabled?
        ENV['BIM_LDAP_ENABLED'] == 'true'
      end

      def authenticate(credentials)
        # LDAP bind
      end
    end

    # Optional 2FA adapter
    class TwoFactorAdapter < Adapter
      def enabled?
        ENV['BIM_2FA_ENABLED'] == 'true'
      end

      def supports_2fa?
        true
      end

      def verify_2fa(user, token)
        # TOTP verification
      end
    end
  end
end

# Configuration
module Bim
  module Authentication
    class Manager
      def self.adapters
        @adapters ||= [
          DatabaseAdapter.new,
          SSOAdapter.new,
          LDAPAdapter.new,
          TwoFactorAdapter.new
        ].select(&:enabled?)
      end

      def self.authenticate(credentials)
        adapters.each do |adapter|
          result = adapter.authenticate(credentials)
          return result if result
        end
        nil
      end
    end
  end
end
```

### Layer 2: BIM Permissions

```ruby
# Add to modules/bim/lib/open_project/bim/engine.rb
module OpenProject::Bim
  class Engine < ::Rails::Engine
    initializer 'bim.register_permissions' do
      OpenProject::AccessControl.map do |map|
        map.project_module :bim do |pm|
          pm.permission :view_ifc_models,
                       { 'bim/ifc_models': [:index, :show] }

          pm.permission :manage_ifc_models,
                       { 'bim/ifc_models': [:create, :update, :destroy] },
                       require: :member

          pm.permission :run_clash_detection,
                       { 'bim/clash_tests': [:create, :run] },
                       require: :member

          pm.permission :manage_bim_baselines,
                       { 'bim/progress_baselines': [:create, :destroy] },
                       require: :member

          pm.permission :view_bim_dashboards,
                       { 'bim/dashboards': [:index, :show] }

          pm.permission :manage_bim_dashboards,
                       { 'bim/dashboards': [:create, :update, :destroy] },
                       require: :member
        end
      end
    end
  end
end
```

### Layer 3: Audit Logging

```ruby
# New: modules/bim/app/models/bim/audit_log.rb
class Bim::AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :project

  enum action_type: {
    model_upload: 0,
    clash_detection_run: 1,
    baseline_created: 2,
    baseline_deleted: 3,
    federation_created: 4,
    comparison_run: 5
  }

  # details: JSONB with action-specific data

  def self.log(user:, project:, action:, details: {})
    create!(
      user: user,
      project: project,
      action_type: action,
      details: details,
      ip_address: RequestStore.store[:current_user_ip]
    )
  end
end

# Usage
Bim::AuditLog.log(
  user: current_user,
  project: project,
  action: :model_upload,
  details: { model_id: ifc_model.id, file_size: ifc_model.file_size }
)
```

### Layer 4: Database Schema

```sql
CREATE TABLE bim_audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  project_id BIGINT REFERENCES projects(id) ON DELETE CASCADE,
  action_type INTEGER NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_logs_user ON bim_audit_logs(user_id);
CREATE INDEX idx_audit_logs_project ON bim_audit_logs(project_id);
CREATE INDEX idx_audit_logs_action ON bim_audit_logs(action_type);
CREATE INDEX idx_audit_logs_created ON bim_audit_logs(created_at);
```

---

## Security Best Practices

1. **Input Validation**: Sanitize IFC file uploads
2. **Authorization Checks**: Verify permissions before all BIM operations
3. **HTTPS Only**: Enforce SSL for BCF API
4. **Rate Limiting**: Prevent clash detection abuse
5. **Audit Trail**: Log all sensitive operations

---

**Deliberation Complete** ✅
**Estimated LOC:** ~600 (Ruby: 600)
**Estimated Duration:** 1 week
**Risk Level:** Low (mostly configuration)
