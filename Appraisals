RAILS_VERSIONS = %w[
  4.2.10
  5.0.7
  5.1.6
  5.2.0
]

RAILS_VERSIONS.each do |version, gems|
  appraise "rails_#{version}" do
    gem 'activejob', version
  end
end
