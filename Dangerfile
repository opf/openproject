CORE_OR_MODULE_MIGRATIONS_REGEX = %r{(modules/.*)?db/migrate/.*\.rb}

def added_or_modified_migrations?
  (git.modified_files + git.added_files).grep(CORE_OR_MODULE_MIGRATIONS_REGEX)
end

if added_or_modified_migrations?
  warn "This PR has migration-related changes on a release branch. Ping @opf/operations"
end
