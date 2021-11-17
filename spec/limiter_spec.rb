describe Rack::Berater do
  before do
    app.use described_class, limiter: limiter, enabled?: enabled?
  end
  let(:limiter) { nil }
  let(:enabled?) { nil }

  let(:app) do
    Rack::Builder.new do
      use Rack::Lint
      run (lambda do |env|
        [200, {'Content-Type' => 'text/plain'}, ['OK']]
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

  context 'without a limiter' do
    before { Berater.test_mode = :fail }

    include_examples 'works nominally'
  end

  describe 'limiter option' do
    context 'when limiter is a limiter' do
      let(:limiter) { ::Berater::Unlimiter.new }

      include_examples 'works nominally'

      it 'calls the limiter' do
        expect(limiter).to receive(:limit).and_call_original
        response
      end

      context 'when operating beyond limits' do
        before { Berater.test_mode = :fail }

        it 'returns an error' do
          expect(response.status).to eq 429
        end
      end
    end

    context 'when limiter is a proc' do
      let(:limiter_instance) { ::Berater::Unlimiter.new }
      let(:limiter) { Proc.new { limiter_instance } }

      include_examples 'works nominally'

      it 'calls the proc with env' do
        expect(limiter).to receive(:call).with(Hash).and_call_original
        response
      end

      context 'when operating beyond limits' do
        before { Berater.test_mode = :fail }

        it 'returns an error' do
          expect(response.status).to eq 429
        end
      end
    end
  end

  describe 'enabled? option' do
    after { expect(response.status).to eq 200 }

    let(:enabled?) { double }

    context 'when there is a limiter' do
      let(:limiter) { ::Berater::Unlimiter.new }

      it 'should be called with the env hash' do
        expect(enabled?).to receive(:call) do |env|
          expect(env).to be_a Hash
          expect(Rack::Request.new(env).path).to eq '/'
        end
      end

      context 'when enabled' do
        it 'should call the limiter' do
          expect(enabled?).to receive(:call).and_return(true)
          expect(limiter).to receive(:limit).and_call_original
        end
      end

      context 'when disabled' do
        it 'should not call the limiter' do
          expect(enabled?).to receive(:call).and_return(false)
          expect(limiter).not_to receive(:limit)
        end
      end
    end

    context 'when there is no limiter' do
      it 'should not call enabled?' do
        expect(enabled?).not_to receive(:call)
      end
    end
  end
end
