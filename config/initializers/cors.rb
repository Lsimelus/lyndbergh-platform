# The contact form and feedback buttons post here from my other sites, so allow their origins
# (from config/sites.yml), the apex lyndbergh.net, and their local dev ports (/factory).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*YAML.load_file(Rails.root.join("config/sites.yml")).map { |site| URI(site["url"]).origin },
            "https://lyndbergh.net",
            *(3000..3004).map { |port| "http://localhost:#{port}" })
    resource "/api/*", headers: :any, methods: %i[post options]
  end
end
