FactoryGirl.define do
  factory :widget do
    sequence(:id)
    name        { "Widget ##{id}" }
    description { "Description of widget ##{id}" }
  end
end