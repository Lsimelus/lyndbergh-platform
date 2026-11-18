# A service's bundled OpenAPI spec (contracts/dist/<name>.json, built by `npm run contracts`).
class Contract
  def self.find(name)
    @cache ||= {}
    @cache[name] ||= new(JSON.parse(Rails.root.join("contracts/dist/#{name}.json").read))
  end

  def initialize(document)
    @openapi = JSONSchemer.openapi(document)
    @document = document
  end

  # Errors (strings) from validating a GET response against the spec; empty when it matches.
  def errors_for(path, status, raw_body)
    responses = @document.dig("paths", path, "get", "responses") or return [ "#{path} is not in the contract" ]
    key = [ status.to_s, "#{status.to_s[0]}XX", "default" ].find { |k| responses.key?(k) } or
      return [ "status #{status} is not documented for #{path}" ]

    pointer = "#/paths/#{escape(path)}/get/responses/#{key}"
    pointer = responses[key]["$ref"] if responses[key]["$ref"]
    schema = @openapi.ref("#{pointer}/content/application~1json/schema")
    schema.validate(JSON.parse(raw_body.to_s)).map { |error| error["error"] }
  rescue JSON::ParserError
    [ "response is not JSON" ]
  end

  private

  def escape(path) = path.gsub("~", "~0").gsub("/", "~1")
end
