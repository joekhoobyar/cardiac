require 'spec_helper'

describe Cardiac::ResourceBuilder do
  
  let(:base_url) { 'http://localhost/prefix/segment?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
  let(:builder)  { Cardiac::ResourceBuilder.new(resource.dup) }
    
  subject { builder }

  shared_examples 'a non-operational resource' do |sym|
    it { is_expected.not_to respond_to(sym) }
    it("##{sym} should raise an error") { expect { builder.send(sym) }.to raise_error }
  end
  
  shared_examples 'a URI builder' do |args,url|
    calldesc = "##{args[0]}(#{args[1..-1].map(&:inspect).join(',')})"
    
    subject { builder.send(*args) }
    
    it "#{calldesc} should modify the new builder" do
      expect(subject.to_resource.to_url).to eq(url)
      unless url == base_url
        expect(subject.to_resource.to_uri).not_to eq(base_uri)
        expect(subject.to_resource.to_url).not_to eq(base_url)
      end
    end
    
    it "#{calldesc} should not modify the original builder" do
      unless url == base_url
        expect(builder.to_resource.to_uri).to eq(base_uri)
        expect(builder.to_resource.to_url).to eq(base_url)
      end
    end
  end
  
  it_behaves_like 'a URI builder', [:scheme, 'https'],     'https://localhost/prefix/segment?q=foobar'
  it_behaves_like 'a URI builder', [:https],               'https://localhost/prefix/segment?q=foobar'
  it_behaves_like 'a URI builder', [:host, 'google.com'],  'http://google.com/prefix/segment?q=foobar'
  it_behaves_like 'a URI builder', [:port, 8080],          'http://localhost:8080/prefix/segment?q=foobar'
  it_behaves_like 'a URI builder', [:path, '1'],           'http://localhost/prefix/segment/1?q=foobar'
  it_behaves_like 'a URI builder', [:query, 'q=barfoo'],   'http://localhost/prefix/segment?q=barfoo'
  it_behaves_like 'a URI builder', [:query, {q: 1, r: 2}], 'http://localhost/prefix/segment?q=1&r=2'
  
  it_behaves_like 'a non-operational resource', :get
  it_behaves_like 'a non-operational resource', :post
  it_behaves_like 'a non-operational resource', :put
  it_behaves_like 'a non-operational resource', :delete
  it_behaves_like 'a non-operational resource', :call
  
end