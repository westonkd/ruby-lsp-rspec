# typed: strict
# frozen_string_literal: true

module RubyLsp
  module RSpec
    class Definition
      include ::RubyLsp::Requests::Support::Common

      #: (ResponseBuilders::CollectionResponseBuilder[Interface::LocationLink | Interface::Location], URI::Generic, NodeContext, RubyIndexer::Index, Prism::Dispatcher) -> void
      def initialize(response_builder, uri, node_context, index, dispatcher)
        @response_builder = response_builder
        @uri = uri
        @node_context = node_context
        @index = index
        dispatcher.register(self, :on_call_node_enter)
      end

      #: (Prism::CallNode) -> void
      def on_call_node_enter(node)
        message = node.message
        return unless message

        return if @node_context.locals_for_scope.include?(message)

        entries = @index[message]
        return unless entries
        return if entries.empty?

        entries.each do |entry|
          # Technically, let can be defined in a different file, but we're not going to handle that case yet
          next unless entry.file_path == @uri.to_standardized_path

          @response_builder << Interface::LocationLink.new(
            target_uri: entry.uri,
            target_range: range_from_location(entry.location),
            target_selection_range: range_from_location(entry.name_location),
          )
        end
      end
    end
  end
end
