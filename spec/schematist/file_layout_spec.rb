# frozen_string_literal: true

require "spec_helper"

# The gem carries no autoloader, so nothing enforces the file layout at runtime. This does:
# every file under lib/ must define the constant its path implies, which is what keeps the
# gem navigable and leaves the door open to dropping an autoloader in later.
RSpec.describe Schematist, "file layout" do
  # version.rb and errors.rb are deliberate exceptions: the gemspec loads the version on its
  # own, and errors.rb defines a hierarchy rather than one path-matching constant.
  let(:exceptions) { %w[schematist/version schematist/errors] }
  let(:acronyms) { {"dsl" => "DSL"} }

  def constant_for(relative_path, acronyms)
    relative_path.split("/").map { |part| acronyms.fetch(part) { part.split("_").map(&:capitalize).join } }.join("::")
  end

  it "defines the constant its path implies, for every file" do
    root = File.expand_path("../../lib", __dir__)

    paths = Dir[File.join(root, "schematist", "**", "*.rb")].map do |path|
      path.delete_prefix("#{root}/").delete_suffix(".rb")
    end - exceptions

    expect(paths).not_to be_empty

    paths.each do |path|
      constant = constant_for(path, acronyms)
      expect(Object.const_defined?(constant)).to be(true), "#{path}.rb does not define #{constant}"
    end
  end

  it "derives nested and acronym constants correctly" do
    expect(constant_for("schematist/dsl/schema_builders", acronyms)).to eq("Schematist::DSL::SchemaBuilders")
    expect(constant_for("schematist/json_output", acronyms)).to eq("Schematist::JsonOutput")
  end
end
