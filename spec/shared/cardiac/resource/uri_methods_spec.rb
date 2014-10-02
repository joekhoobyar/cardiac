require 'spec_helper'

describe Cardiac::UriMethods do
  
  let(:base_url) { 'http://localhost/prefix/segment?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
    
  subject { resource }
    
  describe '#build_query' do
    subject { super().send(:build_query) }
    it { is_expected.to eq('q=foobar')}
  end

  describe '#to_url' do
    subject { super().to_url }
    it { is_expected.to eq(base_url) }
  end

  describe '#to_uri' do
    subject { super().to_uri }
    it { is_expected.to eq(base_uri) }
  end
    
  describe 'scheme built with' do
    # Follow each example with sanity checks.
    after(:each) do 
      scheme = resource.send(:build_scheme)
      expect(resource.scheme(nil).to_uri.scheme).to eq(base_uri.scheme)
      expect(resource.scheme(scheme).to_uri.scheme).to eq(scheme)
    end
        
    describe '#scheme()' do
      subject { lambda{|v| resource.scheme(v).to_uri.scheme } }
        
      describe '[:http]' do
        subject { super()[:http] }
        it { is_expected.to eq('http') }
      end

      describe "['http']" do
        subject { super()['http'] }
        it { is_expected.to eq('http') }
      end

      describe '[:https]' do
        subject { super()[:https] }
        it { is_expected.to eq('https') }
      end

      describe "['https']" do
        subject { super()['https'] }
        it { is_expected.to eq('https') }
      end

      describe '[nil]' do
        subject { super()[nil] }
        it { is_expected.to eq(base_uri.scheme) }
      end
        
      it 'disallows invalid schemes' do
        expect { subject['ftp']   }.to raise_error(ArgumentError)
        expect { subject[0]       }.to raise_error(ArgumentError)
        expect { subject[:mailto] }.to raise_error(ArgumentError)
        expect { subject[false]   }.to raise_error(ArgumentError)
      end
    end
    describe '#ssl()' do
      subject { lambda{|v| resource.ssl(v).to_uri.scheme } }

      describe '[false]' do
        subject { super()[false] }
        it { is_expected.to eq('http') }
      end

      describe '[true]' do
        subject { super()[true] }
        it { is_expected.to eq('https') }
      end

      describe '[nil]' do
        subject { super()[nil] }
        it { is_expected.to eq(base_uri.scheme) }
      end
    end
    describe '#http()' do
      subject { lambda{|| resource.http.to_uri.scheme } }

      describe '[]' do
        subject { super()[] }
        it { is_expected.to eq('http') }
      end
    end
    describe '#https()' do
      subject { lambda{|| resource.https.to_uri.scheme } }

      describe '[]' do
        subject { super()[] }
        it { is_expected.to eq('https') }
      end
    end
  end
  
  describe 'query built with' do
    subject do
      lambda{|*v| builder[resource, *v] ; resource.send(:build_query) }
    end
    
    # Follow each example with sanity checks.
    after(:each) do 
      query = resource.send(:build_query)
      expect(resource.reset_query.send(:build_query)).not_to be_present
      expect(resource.query(query).send(:build_query)).to eq(query)
    end

    # Shared examples that must work for any query builder.    
    shared_examples 'query building' do |builder|
      let(:builder) { builder }
        
      describe "['q=1']" do
        subject { super()['q=1'] }
        it { is_expected.to eq('q=1') }
      end

      describe "['q=4&r=3','s=2&t=1']" do
        subject { super()['q=4&r=3','s=2&t=1'] }
        it { is_expected.to eq('q=4&r=3&s=2&t=1') }
      end

      describe "[{q: 3, s: 1}, 'r=2&t=1']" do
        subject { super()[{q: 3, s: 1}, 'r=2&t=1'] }
        it { is_expected.to eq('q=3&s=1&r=2&t=1') }
      end

      describe "['q=1&t=4',{r: 2, s: 3}]" do
        subject { super()['q=1&t=4',{r: 2, s: 3}] }
        it { is_expected.to eq('q=1&t=4&r=2&s=3') }
      end
        
      it 'disallows invalid queries' do
        expect { subject[%w(a b c)]   }.to raise_error(ArgumentError)
        expect { subject[0]           }.to raise_error(ArgumentError)
        expect { subject[:mailto]     }.to raise_error(ArgumentError)
        expect { subject[false]       }.to raise_error(ArgumentError)
      end
      
      it 'does not modify queries built with a single argument' do
        resource.reset_query
        expect(subject['q=1&q=2']).to eq('q=1&q=2')
        resource.reset_query
        expect(subject['q=1&r=1&q=2']).to eq('q=1&r=1&q=2')
      end
      
      it 'does modify queries built with two or more arguments' do
        resource.reset_query
        expect(subject['q=1&q=2', 'r=1']).to eq('q=2&r=1')
        resource.reset_query
        expect(subject['q=1&r=1&q=2', 'r=2']).to eq('q=2&r=2')
        resource.reset_query
        expect(subject['q=1&r=1&q=2', 'r=2&q=3']).to eq('q=3&r=2')
      end
    end
        
    describe '#query()' do
      include_examples 'query building', Proc.new{|r,*v| r.query(*v) }
    end

    describe '#options()' do
      include_examples 'query building', Proc.new{|r,*l| l.each{|o| r.options(params: o) } }
        
      after(:each) { expect(resource.options_values).to be_empty }
    end
  end 
   
  it 'sets the host' do
    expect(subject.host('example.com').to_uri.host).to eq('example.com')
    expect(subject.host('127.0.0.1').to_uri.host).to eq('127.0.0.1')
  end
    
  it 'sets the port for HTTP' do
    expect(subject.http.to_uri.port).to eq(80)
    expect(subject.http.port(8080).to_uri.port).to eq(8080)
    expect(subject.http.port(nil).to_uri.port).to eq(80)
  end
    
  it 'sets the port for HTTPS' do
    expect(subject.https.to_uri.port).to eq(443)
    expect(subject.https.port(8080).to_uri.port).to eq(8080)
    expect(subject.https.port(nil).to_uri.port).to eq(443)
  end
    
  it 'merges query parameters' do
    expect(subject.query(q: 'barfoo').to_uri.query).to eq('q=barfoo')
    expect(subject.query(q: '1', t: '2').to_uri.query).to eq('q=1&t=2')
    expect(subject.reset_query(t: '3').query(q: 1).query(t: 2).to_uri.query).to eq('t=2&q=1')
    expect(subject.reset_query(q: 'foobar').options(params: {r: 2, s: 'barfoo'}).to_uri.query).to eq('q=foobar&r=2&s=barfoo')
  end
    
  it 'deep_merges query parameters' do
    expect(subject.query(q: {r: 1}).to_uri.query).to eq('q[r]=1')
    expect(subject.query(q: {s: 2}).to_uri.query).to eq('q[r]=1&q[s]=2')
    expect(subject.query('q'=>{t: 3}).to_uri.query).to eq('q[r]=1&q[s]=2&q[t]=3')
  end
    
  it 'resolves relative paths' do
    expect(subject.path('suffix').to_url).to eq('http://localhost/prefix/suffix?q=foobar')
    expect(subject.path('/suffix').to_url).to eq('http://localhost/suffix?q=foobar')
    expect(subject.path('../suffix').to_url).to eq('http://localhost/suffix?q=foobar')
    expect(subject.path('suffix/../addendum').to_url).to eq('http://localhost/addendum?q=foobar')
  end
end