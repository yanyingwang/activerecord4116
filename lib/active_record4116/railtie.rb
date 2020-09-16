require "active_record"
require "rails"
require "active_model/railtie"

# For now, action_controller must always be present with
# rails, so let's make sure that it gets required before
# here. This is needed for correctly setting up the middleware.
# In the future, this might become an optional require.
require "action_controller/railtie"

module ActiveRecord4116
  # = Active Record Railtie
  class Railtie < Rails::Railtie # :nodoc:
    config.active_record = ActiveSupport::OrderedOptions.new

    config.app_generators.orm :active_record, :migration => true,
                                              :timestamps => true

    config.app_middleware.insert_after "::ActionDispatch::Callbacks",
      "ActiveRecord4116::QueryCache"

    config.app_middleware.insert_after "::ActionDispatch::Callbacks",
      "ActiveRecord4116::ConnectionAdapters::ConnectionManagement"

    config.action_dispatch.rescue_responses.merge!(
      'ActiveRecord4116::RecordNotFound'   => :not_found,
      'ActiveRecord4116::StaleObjectError' => :conflict,
      'ActiveRecord4116::RecordInvalid'    => :unprocessable_entity,
      'ActiveRecord4116::RecordNotSaved'   => :unprocessable_entity
    )


    config.active_record.use_schema_cache_dump = true
    config.active_record.maintain_test_schema = true

    config.eager_load_namespaces << ActiveRecord4116

    rake_tasks do
      namespace :db do
        task :load_config do
          ActiveRecord4116::Tasks::DatabaseTasks.database_configuration = Rails.application.config.database_configuration

          if defined?(ENGINE_PATH) && engine = Rails::Engine.find(ENGINE_PATH)
            if engine.paths['db/migrate'].existent
              ActiveRecord4116::Tasks::DatabaseTasks.migrations_paths += engine.paths['db/migrate'].to_a
            end
          end
        end
      end

      load "active_record/railties/databases.rake"
    end

    # When loading console, force ActiveRecord4116::Base to be loaded
    # to avoid cross references when loading a constant for the
    # first time. Also, make it output to STDERR.
    console do |app|
      require "active_record/railties/console_sandbox" if app.sandbox?
      require "active_record/base"
      console = ActiveSupport::Logger.new(STDERR)
      Rails.logger.extend ActiveSupport::Logger.broadcast console
    end

    runner do
      require "active_record/base"
    end

    initializer "active_record.initialize_timezone" do
      ActiveSupport.on_load(:active_record) do
        self.time_zone_aware_attributes = true
        self.default_timezone = :utc
      end
    end

    initializer "active_record.logger" do
      ActiveSupport.on_load(:active_record) { self.logger ||= ::Rails.logger }
    end

    initializer "active_record.migration_error" do
      if config.active_record.delete(:migration_error) == :page_load
        config.app_middleware.insert_after "::ActionDispatch::Callbacks",
          "ActiveRecord4116::Migration::CheckPending"
      end
    end

    initializer "active_record.check_schema_cache_dump" do
      if config.active_record.delete(:use_schema_cache_dump)
        config.after_initialize do |app|
          ActiveSupport.on_load(:active_record) do
            filename = File.join(app.config.paths["db"].first, "schema_cache.dump")

            if File.file?(filename)
              cache = Marshal.load File.binread filename
              if cache.version == ActiveRecord4116::Migrator.current_version
                self.connection.schema_cache = cache
              else
                warn "Ignoring db/schema_cache.dump because it has expired. The current schema version is #{ActiveRecord4116::Migrator.current_version}, but the one in the cache is #{cache.version}."
              end
            end
          end
        end
      end
    end

    initializer "active_record.set_configs" do |app|
      ActiveSupport.on_load(:active_record) do
        app.config.active_record.each do |k,v|
          send "#{k}=", v
        end
      end
    end

    # This sets the database configuration from Configuration#database_configuration
    # and then establishes the connection.
    initializer "active_record.initialize_database" do |app|
      ActiveSupport.on_load(:active_record) do

        class ActiveRecord4116::NoDatabaseError
          remove_possible_method :extend_message
          def extend_message(message)
            message << "Run `$ bin/rake db:create db:migrate` to create your database"
            message
          end
        end

        self.configurations = Rails.application.config.database_configuration
        establish_connection
      end
    end

    # Expose database runtime to controller for logging.
    initializer "active_record.log_runtime" do
      require "active_record/railties/controller_runtime"
      ActiveSupport.on_load(:action_controller) do
        include ActiveRecord4116::Railties::ControllerRuntime
      end
    end

    initializer "active_record.set_reloader_hooks" do |app|
      hook = app.config.reload_classes_only_on_change ? :to_prepare : :to_cleanup

      ActiveSupport.on_load(:active_record) do
        ActionDispatch::Reloader.send(hook) do
          if ActiveRecord4116::Base.connected?
            ActiveRecord4116::Base.clear_cache!
            ActiveRecord4116::Base.clear_reloadable_connections!
          end
        end
      end
    end

    initializer "active_record.add_watchable_files" do |app|
      path = app.paths["db"].first
      config.watchable_files.concat ["#{path}/schema.rb", "#{path}/structure.sql"]
    end
  end
end
