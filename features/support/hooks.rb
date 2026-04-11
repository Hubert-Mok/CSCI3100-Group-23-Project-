# Hooks for Cucumber scenarios
# Database cleanup using ActiveRecord's transaction rollback
Before do
  ActiveRecord::Base.connection.begin_transaction(joinable: false)
end

After do
  if ActiveRecord::Base.connection.transaction_open?
    ActiveRecord::Base.connection.rollback_transaction
  end
end
