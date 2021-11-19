describe Rack::Berater::Prioritizer do
  let(:cache) { described_class.class_variable_get(:@@cache) }

  describe '#call' do
    subject { described_class.new(app) }

    let(:app) { ->(*) { [200, {'Content-Type' => 'text/plain'}, ['OK']] } }
    let(:cache_key) { subject.send(:cache_key_for, env) }
    let(:env) { Rack::MockRequest.env_for('/') }

    specify 'sanity check' do
      expect(app).to receive(:call).and_call_original

      Rack::Lint.new(subject).call(env)
    end

    it 'checks the cache' do
      is_expected.to receive(:cache_get)

      subject.call(env)
    end

    context 'with a cached priority' do
      before do
        allow(subject).to receive(:cache_get).with(cache_key).and_return(priority)
      end

      let(:priority) { '3' }

      after { subject.call(env) }

      it 'sets the priority accordingly' do
        is_expected.to receive(:priority=).with(priority)
      end

      it 'updates the global priority during the request' do
        expect(app).to receive(:call) do
          expect(described_class.current_priority).to eq priority
        end
      end

      it 'resets the priority after the request completes' do
        subject.call(env)
        expect(described_class.current_priority).to be nil
      end
    end

    context 'with an incoming priority header' do
      let(:env) do
        Rack::MockRequest.env_for(
          '/',
          described_class::HEADER => priority,
        )
      end
      let(:priority) { '2' }

      after { subject.call(env) }

      it 'uses the header' do
        is_expected.to receive(:priority=).with(priority)
      end

      it 'ignores any cached value' do
        allow(subject).to receive(:cache_get).with(cache_key).and_return('123')
        is_expected.to receive(:priority=).with(priority)
      end

      it 'resets the priority after the request completes' do
        subject.call(env)
        expect(described_class.current_priority).to be nil
      end
    end

    context 'when the app returns a priority header' do
      let(:app) do
        ->(*) { [200, { described_class::HEADER => priority }, ['OK']] }
      end

      let(:priority) { '5' }

      after { subject.call(env) }

      it 'caches the priority' do
        is_expected.to receive(:cache_set).with(cache_key, priority)
      end

      it 'removes the header' do
        _, headers, _ = subject.call(env)
        expect(headers).not_to include described_class::HEADER
      end

      it 'updates the cache when a different priority is returned' do
        expect(subject).to receive(:cache_get).and_return('123')
        is_expected.to receive(:cache_set).with(cache_key, priority)
      end

      it 'does not update the cache when the same priority is returned' do
        expect(subject).to receive(:cache_get).and_return(priority)
        is_expected.not_to receive(:cache_set)
      end
    end

    it 'does not update the cache when no priority is returned' do
      is_expected.not_to receive(:cache_set)
      subject.call(env)
    end
  end

  describe '#cache_key_for' do
    subject{ described_class.new(nil).send(:cache_key_for, env) }

    context 'with a basic env' do
      let(:env) { Rack::MockRequest.env_for('/') }

      it 'combines the verb and path' do
        is_expected.to match %r{get:/$}
      end
    end

    context 'with a different verb' do
      let(:env) { Rack::MockRequest.env_for('/', method: 'PUT') }

      it 'combines the verb and path' do
        is_expected.to match %r{put:/$}
      end
    end

    context 'with a RESTful path' do
      let(:env) { Rack::MockRequest.env_for('/user/123') }

      it 'normalizes the id' do
        is_expected.to match %r{get:/user/x$}
      end
    end

    context 'with a RESTful path and trailing slash' do
      let(:env) { Rack::MockRequest.env_for('/user/123/') }

      it 'normalizes the id and keeps the trailing slash' do
        is_expected.to match %r{get:/user/x/$}
      end
    end

    context 'with a very RESTful path' do
      let(:env) { Rack::MockRequest.env_for('/user/123/friend/456') }

      it 'normalizes both ids' do
        is_expected.to match %r{get:/user/x/friend/x$}
      end
    end
  end

  context 'as Rack middleware' do
    def call(path = '/')
      get(path).body
    end

    let(:app) do
      headers = {
        'Content-Type' => 'text/plain',
        described_class::HEADER => app_priority,
      }.compact

      Rack::Builder.new do
        use Rack::Lint
        use Rack::Berater::Prioritizer

        run (lambda do |env|
          [200, headers, [ Rack::Berater::Prioritizer.current_priority.to_s ]]
        end)
      end
    end

    let(:app_priority) { nil }

    it 'starts empty' do
      expect(call).to be_empty
    end

    it 'parses incoming priority header' do
      header described_class::HEADER, '7'

      expect(call).to eq '7'
    end

    context 'when app returns a priority header' do
      let(:app_priority) { '8' }

      it 'parses the priority returned from the app' do
        expect(call).to be_empty
        expect(cache.values).to include app_priority
      end

      it 'uses the cached priority for subsequent calls' do
        expect(call).to be_empty
        expect(call).to eq app_priority
      end
    end

    # context 'when two different endpoints are called' do
    #   fit 'parses and caches each priority' do
    #     @app_priority = '6'
    #     expect(call('/six')).to be_empty

    #     expect(call('/six')).to eq '6'

    #     @app_priority = '9'
    #     expect(call('/nine')).to be_empty
    #     expect(call('/nine')).to '9'
    #   end
    # end
  end
end
