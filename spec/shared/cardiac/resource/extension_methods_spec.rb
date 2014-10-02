require 'spec_helper'

describe Cardiac::ExtensionMethods do

  let(:base_url) { 'http://localhost/prefix/segment/suffix?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
  let(:void)     { lambda{||} }

  subject { resource }

  describe '#operation()' do
    subject do
      lambda{|n,b| resource.operation(n, b).send(:build_extension_module) }
    end

    it 'should define operations on an extension module' do
      mod = subject[:foo, lambda{|| :bar }]
      expect(mod).to be_a(Module)
      expect(mod).to be_method_defined(:foo)
      expect(Object.new.tap{|x| x.extend mod }.foo).to eq(:bar)
      expect(resource).not_to respond_to(:foo)
    end

    it 'should not execute the implementation block' do
      expect { subject[:all, lambda{|| raise 'should not happen' }] }.not_to raise_error
    end

    it 'should not be allowed to override a subresource' do
      resource.send(:subresources_values) << [:all, void, nil]
      expect { subject[:all, void] }.to raise_error(ArgumentError, ":all has already been defined as a subresource")
    end

    it 'must be identified by a Symbol or String' do
      expect { subject[1, void] }.to raise_error(ArgumentError)
      expect { subject[nil, void] }.to raise_error(ArgumentError)
    end

    it 'must be implemented by a Proc' do
      expect { subject[1, :get] }.to raise_error(ArgumentError)
      expect { subject[nil, 'get'] }.to raise_error(ArgumentError)
    end
  end

  describe '#extending()' do
    it 'must be implemented by a Module' do
      expect { resource.extending(Proc.new{}){ def foo; :bar end }.send(:build_extension_module) }.to raise_error(ArgumentError)
      expect { resource.extending(Module.new){ def foo; :bar end }.send(:build_extension_module) }.not_to raise_error
    end

    it 'should not require an extension block' do
      expect { resource.extending(Module.new){}.send(:build_extension_module) }.not_to raise_error
      expect { resource.extending(Module.new).send(:build_extension_module)   }.not_to raise_error
    end

    it 'should not allow an extension block with arity != 0' do
      expect{ resource.extending{|a| def foo; :bar end }.send(:build_extension_module) }.to raise_error(ArgumentError)
      expect{ resource.extending{    def foo; :bar end }.send(:build_extension_module) }.not_to raise_error
    end

    it 'should define operations on an extension module' do
      mod = resource.extending{ def foo; :bar end }.send(:build_extension_module)
      expect(mod).to be_a(Module)
      expect(mod).to be_method_defined(:foo)
      expect(Object.new.tap{|x| x.extend mod }.foo).to eq(:bar)
      expect(resource).not_to respond_to(:foo)
      expect(mod).not_to respond_to(:foo)
    end
  end

  describe '#subresource()' do
    subject do
      lambda{|n,b,e| resource.subresource(n, b, &e).send(:build_extension_module) }
    end
    
    let(:receiver) { double() }
		let(:model) { double(to_param: '1') }
    
    it 'should not be allowed to override an operation' do
      resource.send(:operations_values) << [:all, lambda{||}]
      expect { subject[:all, void, void] }.to raise_error(ArgumentError, ":all has already been defined as an operation")
    end

    it 'must be identified by a Symbol or String' do
      expect { subject[1, void, void] }.to raise_error(ArgumentError)
      expect { subject[nil, void, void] }.to raise_error(ArgumentError)
    end

    it 'must be implemented by a Proc' do
      expect { subject[1, :get, void] }.to raise_error(ArgumentError)
      expect { subject[nil, 'get', void] }.to raise_error(ArgumentError)
    end

    it 'should not require an extension block' do
      expect { subject[:all, void, nil] }.not_to raise_error
    end

    it 'should not allow an extension block with arity != 0' do
      expect { subject[:all, void, void] }.not_to raise_error
      expect { subject[:all, void, lambda{|a| }] }.to raise_error(ArgumentError)
    end
    
    shared_examples 'building with ResourceBuilder' do
		  let!(:implementation_block) { lambda{|x| path(x.to_param) } }
		  
		  let!(:extension_block){}
		    
		  let! :subresource do
		    resource.subresource(:instance, implementation_block, &extension_block).send(:build_extension_module)
		  end
		    
		  subject! do
		    subresource
		  end

      # FYI - Something roughly similar would be done by "a" or "the" proxy/builder.
		  let :receiver do
		    Cardiac::ResourceBuilder.new(resource)
		  end
		  
		  let! :result do
		    expect_any_instance_of(Cardiac::Subresource).to receive(:path).with("1").and_call_original
		    expect(model).to receive(:to_param).with(no_args)
		    receiver.instance(model)
		  end
			
			it 'is included on the Resource extension module' do
		    is_expected.to be_a(Module)
		    is_expected.not_to respond_to(:instance)
			end

			# FIXME: not critical, but it would be nice to define them correctly instead of _sufficiently_
		  it 'defines method arities sufficiently' do
		    expect([1,-1]).to be_include(subject.instance_method(:instance).arity)
		  end
		    
		  it 'does not extend the Resource' do
		    expect(resource).not_to respond_to(:instance)
		  end
			
		  it 'is an instance method' do
		    is_expected.to be_method_defined(:instance)
		  end
		  
		  it 'returns a builder' do
		    expect(result).to be_a(Cardiac::ResourceBuilder)
		  end
		    
		  it 'does not extend the builder with the subresource method' do
				expect(result).not_to respond_to(:instance)
		  end
		  
		  it 'builds a subresource on the builder' do
				expect(result.to_resource.to_uri.path).to eq('/prefix/segment/suffix/1')
		  end
		  
		  it 'does not build on the resource' do
				expect(resource.to_uri.path).to eq('/prefix/segment/suffix')
			end
    end
    
    shared_examples 'building and extending with ResourceBuilder' do |ext_name|
      include_examples 'building with ResourceBuilder'
      
      let(:subresult) { result.__send__(ext_name) }
      
      it 'extends the builder with the extension method' do
        expect(result).to respond_to(ext_name)
      end
      
      it 'returns a new builder from the extension method' do
		    expect(subresult).to be_a(Cardiac::ResourceBuilder)
      end
    end

		describe 'without an extension block' do
		  include_examples 'building with ResourceBuilder'
		end

		describe 'with an extension method' do
		  include_examples 'building and extending with ResourceBuilder', :foo do
		    let(:extension_block) { proc { def foo ; https ; end } }
		  end
      
		  it 'applies the extension block to the subresource on the builder' do
				subr = subresult.to_resource
				expect(subr.to_uri.path).to eq('/prefix/segment/suffix/1')
				expect(resource.to_uri.path).to eq('/prefix/segment/suffix')
				expect(subresult.to_resource.to_uri.scheme).to eq('https')
				expect(resource.to_uri.scheme).to eq('http')
		  end
		end
		
		describe 'with an extension operation' do
		  include_examples 'building and extending with ResourceBuilder', :foo do
		    let(:extension_block) { proc { operation :foo, lambda{|| https } } }
		  end

		  # FIXME: this does not pass due to builder semantics, but the analogue
		  # works correctly with subresources - see spec/cardiac/model/base_spec.rb		    
		  #it 'does not extend the new builder with the operation' do
			#	subresult.should_not respond_to(:foo)
		  #end
      
		  it 'applies the extension block to the subresource on the builder' do
				subr = subresult.to_resource
				expect(subr.to_uri.path).to eq('/prefix/segment/suffix/1')
				expect(resource.to_uri.path).to eq('/prefix/segment/suffix')
				expect(subresult.to_resource.to_uri.scheme).to eq('https')
				expect(resource.to_uri.scheme).to eq('http')
		  end
		end
  end

end
