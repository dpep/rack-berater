describe Rack::Berater::Handler do
  let(:app) do
    Rack::Builder.new do
      use Rack::Lint
      run (lambda do |env|
        raise ::Berater::Overloaded if ::Berater.test_mode == :fail
        [200, {"Content-Type" => "text/plain"}, ["OK"]]
      end)
    end
  end
  let(:response) { get "/" }

  shared_examples "works nominally" do
    it { expect(response.status).to eq 200 }
    it { expect(response.body).to eq "OK" }
  end

  context "without Handler" do
    include_examples "works nominally"

    it "does not catch limit errors" do
      Berater.test_mode = :fail
      expect {
        response
      }.to be_overloaded
    end
  end

  context "with Handler using default settings" do
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

  context "with Handler using custom settings" do
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
  end
end
