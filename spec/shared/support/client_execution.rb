shared_context 'Client responses' do
  
  let!(:mock_response_klass) { Struct.new(:body, :code, :headers) }
  
  let!(:mock_success) { mock_response_klass.new("{\"segment\" : {\"id\": 1, \"name\": \"John Doe\"}}", 
                                               200, 'Content-type' => 'application/json') }
    
  let!(:mock_failure) { mock_response_klass.new("<html><head><title>Failed</title></head><body><h1>Failed</h1></body></html>",
                                               404, 'Content-type' => 'text/html') }
  
  let!(:response_builder) { Proc.new{|mock,*args|
    mock = send(:"mock_#{mock}") if Symbol===mock
    Rack::Client::Simple::CollapsedResponse.new(mock.code, mock.headers, StringIO.new(mock.body))
  } } 
  
  let!(:response_handler) { Proc.new{|mock,args|
    response_builder[mock, args]
  } }
  
end

shared_context 'Client execution' do |verb,mock_response|
  before :example do
    allow_any_instance_of(Cardiac::OperationHandler).to receive(:perform_request) do
      response_handler[mock_response]
    end
  end
end