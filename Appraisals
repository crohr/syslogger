# frozen_string_literal: true

RAILS_VERSIONS = %w[
  5.2.6
  6.0.4
  6.1.4
].freeze

RAILS_VERSIONS.each do |version|
  appraise "rails_#{version}" do
    gem 'activejob', version
  end
end
