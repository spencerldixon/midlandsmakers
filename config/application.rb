require_relative "boot"

require "rails"
# Pick the frameworks you want. Action Cable, Action Text and Action Mailbox
# are left out to keep memory down; nothing in the app uses them.
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Midlandsmakers
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # SQLite FTS5 synchronization relies on triggers, which db/schema.rb cannot preserve.
    config.active_record.schema_format = :sql

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Remove trailing slashes from urls
    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 %r{^/(.*)/$}, "/$1"
    end


    mailer_creds = Rails.application.credentials.mailer || {}
    smtp_creds   = Rails.application.credentials.smtp || {}

    config.action_mailer.default_url_options = {
      host: mailer_creds[:default_url_host] || "localhost",
      port: mailer_creds[:default_url_port] || 3000
    }

    if smtp_creds[:address].present?
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = true
      config.action_mailer.smtp_settings = {
        address:              smtp_creds[:address],
        port:                 smtp_creds[:port] || 587,
        domain:               smtp_creds[:domain],
        user_name:            smtp_creds[:user_name],
        password:             smtp_creds[:password],
        authentication:       :plain,
        enable_starttls_auto: true
      }
    end

    # Kill switch for new sign-ups (existing users can still sign in) — see
    # Users::RegistrationsController. Defaults to open; set
    # REGISTRATION_ENABLED=false (.env in development/test, a real env var
    # in production) to close it.
    config.x.registration_enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("REGISTRATION_ENABLED", "true"))
  end
end
