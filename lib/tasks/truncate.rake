# frozen_string_literal: true

namespace :db do
  desc "Truncate all tables (clear data, keep structure)"
  task truncate_all: :environment do
    # Skip Rails internal and migration tables so structure stays intact
    skip_tables = %w[schema_migrations ar_internal_metadata]

    conn = ActiveRecord::Base.connection

    # PostgreSQL: disable triggers so foreign keys don't block truncate
    conn.execute("SET session_replication_role = 'replica';")

    conn.tables.each do |table|
      next if skip_tables.include?(table)

      conn.execute("TRUNCATE TABLE #{conn.quote_table_name(table)} RESTART IDENTITY CASCADE;")
      puts "Truncated: #{table}"
    end

    conn.execute("SET session_replication_role = 'origin';")
    puts "Done. All table data cleared, schema unchanged."
  end
end
