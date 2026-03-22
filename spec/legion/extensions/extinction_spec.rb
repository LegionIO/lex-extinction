# frozen_string_literal: true

RSpec.describe Legion::Extensions::Extinction do
  it 'defines a VERSION constant' do
    expect(Legion::Extensions::Extinction::VERSION).to be_a(String)
    expect(Legion::Extensions::Extinction::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it 'loads Helpers::Levels' do
    expect(defined?(Legion::Extensions::Extinction::Helpers::Levels)).to be_truthy
  end

  it 'loads Runners::Extinction' do
    expect(defined?(Legion::Extensions::Extinction::Runners::Extinction)).to be_truthy
  end
end
