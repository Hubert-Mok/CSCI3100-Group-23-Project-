# Hooks for Cucumber scenarios
# Database cleanup using truncation so each scenario starts with a fresh state.
Before do
  tables = ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata]

  ActiveRecord::Base.connection.disable_referential_integrity do
    tables.each do |table|
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE")
    end
  end
end

After do
  Capybara.reset_sessions!
  Capybara.use_default_driver
end
