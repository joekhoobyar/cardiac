class ExampleBase < Cardiac::Model::Base
  self.base_resource = 'http://example.com'
end

class Widget < ExampleBase
  attribute :id,          type: Integer
  attribute :name,        type: String
  attribute :description, type: String
end
