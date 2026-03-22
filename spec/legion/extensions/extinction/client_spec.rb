# frozen_string_literal: true

require 'legion/extensions/extinction/client'

RSpec.describe Legion::Extensions::Extinction::Client do
  subject(:client) { described_class.new }

  it 'can be instantiated with no arguments' do
    expect { described_class.new }.not_to raise_error
  end

  it 'accepts keyword opts' do
    c = described_class.new(timeout: 30)
    expect(c.settings[:options][:timeout]).to eq(30)
  end

  it 'provides settings method' do
    expect(client.settings).to be_a(Hash)
    expect(client.settings[:options]).to be_a(Hash)
  end

  it 'includes Runners::Extinction' do
    expect(client).to respond_to(:extinction_status)
    expect(client).to respond_to(:escalate)
    expect(client).to respond_to(:deescalate)
    expect(client).to respond_to(:monitor_protocol)
    expect(client).to respond_to(:archive_agent)
    expect(client).to respond_to(:full_termination)
  end
end
