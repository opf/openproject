# CDE Plugin - Manual Installation Instructions

## What's Been Done

✅ **All code fixes are complete:**
1. Migrations copied to plugin directory
2. `cde_conventions.yml` created
3. `aasm` gem added to `Gemfile.modules`
4. JSON helpers added to `AuditEvent`

✅ **Ruby 3.3.12 downloaded:**
- Location: `C:\Users\andyphung\Downloads\rubyinstaller-3.3.12.exe`
- Size: 16.3 MB
- SHA256: `c6b505436853c36e3257e21b59752e032c17b6ae4d4f0240e1d47872d3cde756`

## Next Steps (You Must Do Manually)

### Step 1: Install Ruby
```powershell
# Run as Administrator
"C:\Users\andyphung\Downloads\rubyinstaller-3.3.12.exe" /VERYSILENT /NORESTART /SP-
```

### Step 2: Install VC++ Redistributable (Required for UCRT)
```powershell
# Download and install
curl -L "https://aka.ms/vs/17/release/vc_redist.x64.exe" -o "$env:USERPROFILE\Downloads\vc_redist.x64.exe"
Start-Process "$env:USERPROFILE\Downloads\vc_redist.x64.exe" -Wait
```

### Step 3: Open MSYS2 Shell
```powershell
# Launch MSYS2 from Ruby installation
& "C:\Ruby33-x64\msys64\msys2.exe"
```

### Step 4: Run Installation
```bash
# Inside MSYS2 shell:
cd "/c/Users/andyphung/My Drive/nexuscde"
bundle install
bundle exec rake db:migrate
bundle exec rspec modules/cde/spec/integration/
```

## Slice Status

| Slice | Status |
|-------|--------|
| 1-6, 9 | ✅ Complete (infrastructure) |
| 7, 8 | ⏳ Pending |
| 10-14 | ⏳ Pending |

## Current Issues

1. **VC++ Redistributable Missing** - Ruby UCRT build requires this
2. **SSL Certificate Issues** - System has expired certificates
3. **Bundler Cannot Run** - Due to missing UCRT dependencies

## Alternative: Use Docker

```bash
cd D:/nexuscde
docker-compose up -d
docker exec -it nexuscde-backend bash
bundle install
bundle exec rake db:migrate
```

## Verification

After successful installation:
```bash
cd D:/nexuscde
bundle exec rails runner "puts Cde::Engine.name"
# Should output: openproject_cde
```

---

**Summary:** Code is ready. Ruby is downloaded. You need to:
1. Install Ruby (run the .exe)
2. Install VC++ Redistributable
3. Run bundle commands in MSYS2 shell
