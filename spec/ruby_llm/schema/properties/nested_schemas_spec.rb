# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "nested schemas" do
  let(:person_schema) do
    Class.new(described_class) do
      string :name, description: "Person's name"
      integer :age, description: "Person's age"
    end
  end

  let(:address_schema) do
    Class.new(described_class) do
      string :street, description: "Street address"
      string :city, description: "City name"
      string :zipcode, description: "Postal code"
    end
  end

  let(:person_schema_hash) do
    {
      type: "object",
      properties: {
        name: {type: "string", description: "Person's name"},
        age: {type: "integer", description: "Person's age"}
      },
      required: %i[name age],
      additionalProperties: false
    }
  end

  # The rendered document is the JSON form of the same structure
  let(:person_document_hash) { JSON.parse(JSON.generate(person_schema_hash)) }

  let(:address_schema_hash) do
    {
      type: "object",
      properties: {
        street: {type: "string", description: "Street address"},
        city: {type: "string", description: "City name"},
        zipcode: {type: "string", description: "Postal code"}
      },
      required: %i[street city zipcode],
      additionalProperties: false
    }
  end

  before do
    stub_const("PersonSchema", person_schema)
    stub_const("AddressSchema", address_schema)
  end

  it "supports deeply nested objects" do
    schema_class = Class.new(described_class)
    schema_class.object :level1 do
      object :level2 do
        object :level3 do
          string :deep_value
        end
      end
    end

    instance = schema_class.new
    properties = instance.to_json_schema["properties"]

    level3 = properties["level1"]["properties"]["level2"]["properties"]["level3"]
    expect(level3["properties"]["deep_value"]).to eq({"type" => "string"})
  end

  it "supports arrays of schema classes" do
    schema_class = Class.new(described_class)
    schema_class.array :employees, of: PersonSchema

    properties = schema_class.properties
    expect(properties[:employees]).to eq({
      type: "array",
      items: person_schema_hash
    })
    expect(schema_class.definitions).to be_empty
  end

  it "supports arrays of schema classes with description" do
    schema_class = Class.new(described_class)
    schema_class.array :team_members, of: PersonSchema, description: "List of team members"

    properties = schema_class.properties
    expect(properties[:team_members]).to eq({
      type: "array",
      description: "List of team members",
      items: person_schema_hash
    })
  end

  it "handles multiple schema insertions" do
    company_schema = Class.new(described_class)
    company_schema.string :name
    company_schema.array :employees, of: PersonSchema
    company_schema.object :headquarters, of: AddressSchema
    company_schema.object :founder do
      PersonSchema.new
    end

    properties = company_schema.properties
    expect(properties[:employees]).to eq({type: "array", items: person_schema_hash})
    expect(properties[:headquarters]).to eq(address_schema_hash)
    expect(properties[:founder]).to eq(person_schema_hash)
    expect(company_schema.definitions).to be_empty
  end

  it "creates separate inline schemas for each usage" do
    company_schema = Class.new(described_class)
    company_schema.array :employees, of: PersonSchema
    company_schema.object :ceo, of: PersonSchema
    company_schema.object :founder do
      PersonSchema.new
    end

    properties = company_schema.properties

    expect(properties[:employees][:items]).to eq(person_schema_hash)
    expect(properties[:ceo]).to eq(person_schema_hash)
    expect(properties[:founder]).to eq(person_schema_hash)
    expect(company_schema.definitions).to be_empty
  end

  it "generates proper JSON schema output with inline schemas" do
    company_schema = Class.new(described_class)
    company_schema.string :name
    company_schema.array :employees, of: PersonSchema
    company_schema.object :founder, of: PersonSchema

    stub_const("CompanySchema", company_schema)
    instance = company_schema.new("CompanySchema")

    json_output = instance.to_json_schema
    expect(json_output["type"]).to eq("object")
    expect(json_output["properties"]["employees"]["items"]).to eq(person_document_hash)
    expect(json_output["properties"]["founder"]).to eq(person_document_hash)
    expect(json_output).not_to have_key("$defs")
  end
end
