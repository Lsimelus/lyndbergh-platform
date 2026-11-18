# A monitored site, read from config/sites.yml.
Site = Data.define(:slug, :name, :url, :health_path, :repo, :expect) do
  def self.all
    @all ||= YAML.load_file(Rails.root.join("config/sites.yml")).map do |attrs|
      new(health_path: nil, expect: nil, **attrs.symbolize_keys)
    end
  end

  def self.find(slug) = all.find { |site| site.slug == slug } || raise(ActiveRecord::RecordNotFound, "No site #{slug}")

  def check_url = URI.join(url, health_path || "/").to_s

  def links
    {
      "Live" => url,
      "Repo" => "https://github.com/#{repo}",
      "CI" => "https://github.com/#{repo}/actions",
      "Dependabot" => "https://github.com/#{repo}/security/dependabot"
    }
  end

  def checks = Check.where(site_slug: slug)
end
