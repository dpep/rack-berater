module Rack
  class Berater
    class GraphqlPrioritizer < Prioritizer
      def cache_key_for(env)
        request = Rack::Request.new(env)

        if request.path == '/graphql'
          parts = [ 'graphql' ]

          if request.params['operationName']
            parts << request.params['operationName']
          elsif request.params['query']
            op = begin
              GraphQL.parse(request.params['query']).definitions.find do |x|
                x.is_a? GraphQL::Language::Nodes::OperationDefinition
              end
            rescue GraphQL::ParseError
              nil
            end

            parts << op.name if op
          end

          parts.join(':')
        else
          super
        end
      end
    end
  end
end
