# CDE Plugin - Ruby Installation Blocked

## Status: Cannot Install Ruby Automatically

### Root Cause
System has SSL certificate issues preventing downloads from GitHub:
- `WINHTTP_CALLBACK_STATUS_FLAG_CERT_REV_FAILED`
- `WINHTTP_CALLBACK_STATUS_FLAG_INVALID_CA`

### Attempts Made
1. ❌ winget install - Failed due to SSL certificate issues
2. ❌ Chocolatey - Failed (not elevated, wrong source)
3. ❌ curl from GitHub releases - Failed (SSL invalid CA)
4. ❌ Direct GitHub API - No Windows builds available in ruby-builder

### What's Fixed
All CDE plugin code is ready:
- ✅ Migrations copied to correct location
- ✅ `cde_conventions.yml` created
- ✅ `aasm` gem added to Gemfile.modules
- ✅ JSON helpers added to AuditEvent model
- ✅ 5 migration files in `modules/cde/db/migrate/`

### Manual Fix Required

**Option 1: Download Ruby Manually**
1. Open browser on this machine
2. Go to: https://github.com/oneclick/rubyinstaller2/releases/tag/RubyInstaller-3.3.12-1
3. Download: `rubyinstaller-3.3.12-1-x64.exe`
4. Run installer and add Ruby to PATH
5. Open new terminal and run:
   ```bash
   cd D:/nexuscde
   bundle install
   bundle exec rake db:migrate
   bundle exec rspec modules/cde/spec/integration/
   ```

**Option 2: Fix SSL Certificates**
```powershell
# Run as Administrator
Update-TrustedRootCertificate -Url https://github.com
```

**Option 3: Use Existing Docker Setup**
```bash
cd D:/nexuscde
docker-compose up -d
docker exec -it nexuscde-backend bash
bundle install
bundle exec rake db:migrate
```

---

## Plugin Status

| Slice | Status |
|-------|--------|
| 1-6, 9 | ✅ Infrastructure complete |
| 7, 8 | ⏳ Pending |
| 10-14 | ⏳ Pending |

## Files Ready
- `D:/nexuscde/modules/cde/` - Plugin code (16 files)
- `D:/nexuscde/modules/cde/db/migrate/` - 5 migrations
- `D:/nexuscde/modules/cde/config/cde_conventions.yml` - Config
- `D:/nexuscde/Gemfile.modules` - aasm gem added
