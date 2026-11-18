ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # A stand-in for Net::HTTP: returns `code` and a JSON `body` for any URI.
  FakeResponse = Struct.new(:code, :body)

  def respond_with(code, body)
    ->(_uri) { FakeResponse.new(code.to_s, body.is_a?(String) ? body : body.to_json) }
  end
end
