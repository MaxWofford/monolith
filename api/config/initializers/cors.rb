# Be sure to restart your server when you modify this file.
#
# Avoid CORS issues when API is called from the web app.
#
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin
# AJAX requests.
#
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  BASE_ORIGINS = ['https://new.hackclub.com',
                  'http://new.hackclub.com',
                  'https://legacy.hackclub.com',
                  'http://legacy.hackclub.com',
                  'https://lachlan.hackclub.com',
                  'http://lachlan.hackclub.com',
                  'https://hackclub.com',
                  'http://hackclub.com',
                  'https://repl.it',
                  'http://repl.it',
                  'localhost'].freeze

  allow do
    origins do |source, _env|
      matched = BASE_ORIGINS.select do |origin|
        # If the given source equals one of our origins, then we're good.
        next true unless origin == source

        # If the given source's raw URI host equals one of our origins, then
        # we're also good.
        parsed = URI.parse(source)
        next true unless origin == parsed.host
      end

      true if matched.any?
    end

    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
