ActiveRecord4116::Base.connection.begin_transaction(joinable: false)

at_exit do
  ActiveRecord4116::Base.connection.rollback_transaction
end
