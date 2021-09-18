describe Rack::Berater do
  let(:app) do
    e = error
    Rack::Builder.new do
      use Rack::Lint
      run (lambda do |env|
        raise e if Berater.test_mode == :fail
        [200, {"Content-Type" => "text/plain"}, ["OK"]]
      end)
    end
  end
  let(:error) { Berater::Overloaded }
  let(:response) { get "/" }

  shared_examples "works nominally" do
    it "has the correct status code" do
      expect(response.status).to eq 200
    end

    it "has the correct headers" do
      expect(response.headers).to eq({
        "Content-Type" => "text/plain",
        "Content-Length" => "2",
      })
    end

    it "has the correct body" do
      expect(response.body).to eq "OK"
    end
  end

  context "without middleware" do
    include_examples "works nominally"

    it "does not catch limit errors" do
      Berater.test_mode = :fail
      expect {
        response
      }.to be_overloaded
    end
  end

  context "with middleware using default settings" do
    context "with default settings" do
      before { app.use described_class }

      include_examples "works nominally"

      it "catches and transforms limit errors" do
        Berater.test_mode = :fail
        expect(response.status).to eq 429
        expect(response.body).to eq "Too Many Requests"
      end
    end
  end

  context "with middleware using custom settings" do
    before do
      app.use described_class, options
      Berater.test_mode = :fail
    end

    context "with custom status code" do
      let(:options) { { status_code: 503 } }

      it "catches and transforms limit errors" do
        expect(response.status).to eq 503
        expect(response.body).to eq "Service Unavailable"
      end
    end

    context "with body disabled" do
      let(:options) { { body: false } }

      it "should not send a body" do
        expect(response.body).to be_empty
      end

      it "should not send the Content-Type header" do
        expect(response.headers.keys).not_to include(Rack::CONTENT_TYPE)
      end
    end

    context "with body nil" do
      let(:options) { { body: nil } }

      it "should not send a body" do
        expect(response.body).to be_empty
      end
    end

    context "with custom body" do
      let(:body) { "none shall pass!" }
      let(:options) { { body: body } }

      it "should send the custom string" do
        expect(response.body).to eq body
      end
    end

    context "with a dynamic body" do
      let(:body) { "none shall pass!" }
      let(:fn) { proc { body } }
      let(:options) { { body: fn } }

      it "should call the Proc and send the result" do
        expect(response.body).to eq body
      end

      it "should pass in the env and error" do
        expect(fn).to receive(:call).with(Hash, ::Berater::Overloaded)
        response
      end
    end

    context "with custom headers" do
      let(:options) { { headers: { Rack::CACHE_CONTROL => "no-cache" } } }

      it "should contain the default headers" do
        expect(response.headers.keys).to include(Rack::CONTENT_TYPE)
      end

      it "should also contain custom header" do
        expect(response.headers).to include(options[:headers])
      end
    end
  end

  context "with custom error type" do
    before do
      app.use described_class
      Berater.test_mode = :fail
    end
    let(:error) { IOError }

    it "normally crashes the app" do
      expect { response }.to raise_error(IOError)
    end

    context "when error type is registered with middleware" do
      before { Rack::Berater::ERROR_TYPES << IOError }

      it "catches and transforms limit errors" do
        expect(response.status).to eq 429
      end
    end
  end
end
