# frozen_string_literal: true

RAILS_VERSIONS = %w[
  5.2.4
  6.0.3
  6.1.0
].freeze

RAILS_VERSIONS.each do |version|
  appraise "rails_#{version}" do
    gem 'activejob', version
  end
end
