# class MySubclass < Rack::Berater
#   def enabled?(env)
#     Rack::Request.new(env).path == '/overloaded'
#   end

#   def limit(&block)
#     raise Berater::Overloaded
#   end
# end

# describe MySubclass do
#   before do
#     app.use described_class
#   end

#   let(:app) do
#     Rack::Builder.new do
#       use Rack::Lint
#       run (lambda do |env|
#         [200, {"Content-Type" => "text/plain"}, ["OK"]]
#       end)
#     end
#   end

#   context "when hitting /overloaded" do
#     let(:url) { "/overloaded" }

#     it "raises" do

#     end
#   end

# end
