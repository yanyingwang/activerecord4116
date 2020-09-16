require_relative 'gem_version'

module ActiveRecord4116
  # Returns the version of the currently loaded ActiveRecord4116 as a <tt>Gem::Version</tt>
  def self.version
    gem_version
  end
end
