class Dummy < Cardiac::Model::Base
  self.base_resource = 'http://localhost/dummy'
  
  attribute :id,     type: Integer
  attribute :name,   type: String
  
end