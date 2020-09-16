require 'active_support/logger'
require 'models/college'
require 'models/course'

module ARTest
  def self.connection_name
    ENV['ARCONN'] || config['default_connection']
  end

  def self.connection_config
    config['connections'][connection_name]
  end

  def self.connect
    puts "Using #{connection_name}"
    ActiveRecord4116::Base.logger = ActiveSupport::Logger.new("debug.log", 0, 100 * 1024 * 1024)
    ActiveRecord4116::Base.configurations = connection_config
    ActiveRecord4116::Base.establish_connection :arunit
    ARUnit2Model.establish_connection :arunit2
  end
end
