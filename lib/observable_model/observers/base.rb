module ObservableModel
  module Observers
    class Base
      def initialize(observable)
        @observable = observable
      end

      def on_create_commit; end

      def on_update_commit; end

      def on_destroy_commit; end
    end
  end
end
