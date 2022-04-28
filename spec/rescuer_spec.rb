describe Rack::Berater do
  let(:app) do
    Rack::Builder.new do
      use Rack::Lint
      run (lambda do |env|
        Berater(:key, 1) do
          [200, {'Content-Type' => 'text/plain'}, ['OK']]
        end
      end)
    end
  end
  let(:response) { get '/' }

  shared_examples 'works nominally' do
    it 'has the correct status code' do
      expect(response.status).to eq 200
    end

    it 'has the correct headers' do
      expect(response.headers).to eq({
        'Content-Type' => 'text/plain',
        'Content-Length' => '2',
      })
    end

    it 'has the correct body' do
      expect(response.body).to eq 'OK'
    end
  end

  context 'without middleware' do
    include_examples 'works nominally'

    it 'does not catch limit errors' do
      Berater.test_mode = :fail
      expect {
        response
      }.to be_overloaded
    end
  end

  context 'with middleware using default settings' do
    before { app.use described_class }

    include_examples 'works nominally'

    it 'catches and transforms limit errors' do
      Berater.test_mode = :fail
      expect(response.status).to eq 429
      expect(response.body).to eq 'Too Many Requests'
    end
  end

  context 'with middleware using custom settings' do
    before do
      app.use described_class, options
      Berater.test_mode = :fail
    end

    context 'with a custom body' do
      context 'with body nil' do
        let(:options) { { body: nil } }

        it 'falls back to the default' do
          expect(response.body).to eq 'Too Many Requests'
        end
      end

      context 'with body disabled' do
        let(:options) { { body: false } }

        it 'should not send a body' do
          expect(response.body).to be_empty
        end

        it 'should not send the Content-Type header' do
          expect(response.headers.keys).not_to include(Rack::CONTENT_TYPE)
        end
      end

      context 'with a string' do
        let(:body) { 'none shall pass!' }
        let(:options) { { body: body } }

        it 'should send the custom string' do
          expect(response.body).to eq body
        end
      end

      context 'with an erroneous value' do
        let(:options) { { body: 123 } }

        it 'should raise an error' do
          expect {
            response
          }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with custom headers' do
      context 'with an extra header' do
        let(:options) { { headers: { Rack::CACHE_CONTROL => 'no-cache' } } }

        it 'should contain the default headers' do
          expect(response.headers.keys).to include(Rack::CONTENT_TYPE)
        end

        it 'should also contain the custom header' do
          expect(response.headers).to include(options[:headers])
        end
      end

      context 'with a new content type' do
        let(:options) { { headers: { Rack::CONTENT_TYPE => 'application/json' } } }

        it 'should override the Content-Type header' do
          expect(response.headers).to include(options[:headers])
        end
      end
    end

    context 'with custom status code' do
      let(:options) { { status_code: 503 } }

      it 'catches and transforms limit errors' do
        expect(response.status).to eq 503
        expect(response.body).to eq 'Service Unavailable'
      end
    end
  end

  context 'with custom error type' do
    before do
      app.use described_class
      expect(Berater::Limiter).to receive(:new).and_raise(IOError)
    end

    it 'normally crashes the app' do
      expect { response }.to raise_error(IOError)
    end

    context 'when an error type is registered with middleware' do
      around do |example|
        Rack::Berater::ERRORS << IOError
        example.run
        Rack::Berater::ERRORS.delete(IOError)
      end

      it 'catches and transforms limit errors' do
        expect(response.status).to eq 429
      end
    end
  end
end
