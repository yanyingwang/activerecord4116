
module ActiveRecord4116
  # = Active Record Query Cache
  class QueryCache
    module ClassMethods
      # Enable the query cache within the block if Active Record is configured.
      # If it's not, it will execute the given block.
      def cache(&block)
        if ActiveRecord4116::Base.connected?
          connection.cache(&block)
        else
          yield
        end
      end

      # Disable the query cache within the block if Active Record is configured.
      # If it's not, it will execute the given block.
      def uncached(&block)
        if ActiveRecord4116::Base.connected?
          connection.uncached(&block)
        else
          yield
        end
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      enabled       = ActiveRecord4116::Base.connection.query_cache_enabled
      connection_id = ActiveRecord4116::Base.connection_id
      ActiveRecord4116::Base.connection.enable_query_cache!

      response = @app.call(env)
      response[2] = Rack::BodyProxy.new(response[2]) do
        restore_query_cache_settings(connection_id, enabled)
      end

      response
    rescue Exception => e
      restore_query_cache_settings(connection_id, enabled)
      raise e
    end

    private

    def restore_query_cache_settings(connection_id, enabled)
      ActiveRecord4116::Base.connection_id = connection_id
      ActiveRecord4116::Base.connection.clear_query_cache
      ActiveRecord4116::Base.connection.disable_query_cache! unless enabled
    end

  end
end
