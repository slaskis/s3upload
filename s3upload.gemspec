# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{s3upload}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Robert Sk\303\266ld"]
  s.date = %q{2010-01-22}
  s.description = %q{A jQuery plugin for direct upload to an Amazon S3 bucket.}
  s.email = %q{}
  s.executables = ["jquery.s3upload.min.js", "s3upload.swf"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md", "bin/jquery.s3upload.min.js", "bin/s3upload.swf", "lib/s3upload.rb"]
  s.files = ["CHANGELOG", "LICENSE", "Manifest", "README.md", "Rakefile", "bin/jquery.s3upload.min.js", "bin/s3upload.swf", "hx_src/MimeTypes.hx", "hx_src/S3Upload.hx", "hx_src/build.hxml", "js_src/jquery.s3upload.js", "lib/s3upload.rb", "s3upload.gemspec"]
  s.homepage = %q{http://github.com/slaskis/s3upload}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "S3upload", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{s3upload}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A jQuery plugin for direct upload to an Amazon S3 bucket.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
