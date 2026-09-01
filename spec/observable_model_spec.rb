# frozen_string_literal: true

RSpec.describe ObservableModel do
  it "has a version number" do
    expect(ObservableModel::VERSION).not_to be nil
  end
end
