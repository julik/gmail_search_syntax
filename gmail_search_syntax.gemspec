Gem::Specification.new do |s|
  s.name = "gmail_search_syntax"
  s.version = "0.1.0"
  s.summary = "Gmail search syntax parser"
  s.authors = ["me@julik.nl"]
  s.license = "MIT"
  s.homepage = "https://github.com/julik/gmail_search_syntax"
  s.required_ruby_version = ">= 3.0"
  
  s.files = Dir[
    "lib/**/*.{rb,md}",
    "test/**/*.rb",
    "examples/**/*.rb",
    "*.md",
    "Rakefile"
  ]
  s.require_paths = ["lib"]

  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "sqlite3", "< 1.6"
  s.add_development_dependency "standard", "~> 1.0"
end
