# frozen_string_literal: true

require_relative "observable_model/version"
require_relative "observable_model/observers/base"
require_relative "observable_model/sources/active_record_observable"

module ObservableModel
  class Error < StandardError; end
end
