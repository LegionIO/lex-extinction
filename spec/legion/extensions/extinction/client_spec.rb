# frozen_string_literal: true

require 'legion/extensions/extinction/client'

RSpec.describe Legion::Extensions::Extinction::Client do
  it 'responds to extinction runner methods' do
    client = described_class.new
    expect(client).to respond_to(:escalate)
    expect(client).to respond_to(:deescalate)
    expect(client).to respond_to(:extinction_status)
    expect(client).to respond_to(:check_reversibility)
  end
end
