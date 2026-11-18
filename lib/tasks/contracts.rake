namespace :contracts do
  ENVELOPE_URL = %r{https://raw\.githubusercontent\.com/Lsimelus/lyndbergh-platform/[^/]+/contracts/common/envelope\.yaml}

  desc "Copy each service's openapi.yaml (config/contracts.yml) into contracts/vendor/ (needs `gh` signed in)"
  task :pull do
    YAML.load_file(Rails.root.join("config/contracts.yml")).each do |name, source|
      spec, status = Open3.capture2("gh", "api", "repos/#{source["repo"]}/contents/#{source["path"]}?ref=#{source["ref"]}",
                                    "-H", "Accept: application/vnd.github.raw")
      abort "Could not fetch #{name} from #{source["repo"]}" unless status.success?

      # Services point at the shared envelope by URL; resolve it locally so the platform checks against its own copy.
      spec = spec.gsub(ENVELOPE_URL, "../../common/envelope.yaml")
      path = Rails.root.join("contracts/vendor/#{name}/openapi.yaml")
      FileUtils.mkdir_p(path.dirname)
      File.write(path, spec)
      puts "#{name}: #{source["repo"]}@#{source["ref"]} -> #{path.relative_path_from(Rails.root)}"
    end
    puts "Now run `npm run contracts` to bundle and regenerate types."
  end
end
