require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SpotManager
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.eager_load_paths += ["#{Rails.root}/lib"]
    config.eager_load_paths += Dir["#{Rails.root}/lib/**/"]

    config.i18n.load_path += Dir[File.join(Rails.root.to_s, 'config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.available_locales = [:"zh-CN", :zh, :en]
    config.i18n.default_locale = 'zh-CN'

    config.exceptions_app = self.routes
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    config.cache_store = :redis_cache_store, {
      url: ENV["SIDEKIQ_REDIS_URL"] || "redis://localhost:6379/1",
      pool_size: 5,
      pool_timeout: 5
    }

    ENV.fetch('RAILS_HOST_NAME').split(",").each do |h|
      config.hosts << h
    end

    config.host_authorization = { exclude: ->(request) { request.path =~ /healthcheck/ } }
  end
end
