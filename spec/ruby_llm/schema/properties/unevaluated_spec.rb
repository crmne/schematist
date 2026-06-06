# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "unevaluated keywords" do
  let(:schema_class) { Class.new(described_class) }

  it "supports unevaluatedProperties on composition schemas" do
    schema_class.all_of :person do
      object do
        string :name
      end

      object do
        integer :age
      end

      unevaluated_properties false
    end

    person_schema = schema_class.properties[:person]

    expect(person_schema[:allOf].length).to eq(2)
    expect(person_schema[:unevaluatedProperties]).to be(false)
  end

  it "supports unevaluatedProperties on referenced object schemas" do
    schema_class.define :person do
      string :name
    end

    schema_class.object :person, of: :person, unevaluated_properties: false

    expect(schema_class.properties[:person]).to eq({
      "$ref" => "#/$defs/person",
      unevaluatedProperties: false
    })
  end

  it "supports unevaluatedProperties on inline object schemas" do
    schema_class.object :metadata, unevaluated_properties: false do
      string :name
    end

    metadata_schema = schema_class.properties[:metadata]

    expect(metadata_schema[:properties][:name]).to eq({type: "string"})
    expect(metadata_schema[:unevaluatedProperties]).to be(false)
  end

  it "supports unevaluatedItems on array schemas" do
    schema_class.array :values, of: :integer, unevaluated_items: false

    expect(schema_class.properties[:values]).to eq({
      type: "array",
      items: {type: "integer"},
      unevaluatedItems: false
    })
  end
end
