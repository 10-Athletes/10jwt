# -*- encoding: utf-8 -*-
# stub: rails_real_favicon 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_real_favicon".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Philippe Bernard".freeze]
  s.date = "2020-02-10"
  s.description = "Generate and install a favicon for all platforms with RealFaviconGenerator.".freeze
  s.email = ["philippe@realfavicongenerator.net".freeze]
  s.homepage = "https://github.com/RealFaviconGenerator/rails_real_favicon".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Manage the favicon of your RoR project with RealFaviconGenerator".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rails>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<json>.freeze, [">= 1.7", "< 3"])
    s.add_runtime_dependency(%q<rubyzip>.freeze, ["~> 2"])
  else
    s.add_dependency(%q<rails>.freeze, [">= 0"])
    s.add_dependency(%q<json>.freeze, [">= 1.7", "< 3"])
    s.add_dependency(%q<rubyzip>.freeze, ["~> 2"])
  end
end
