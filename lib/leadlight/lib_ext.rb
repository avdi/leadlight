Dir.glob(File.expand_path("../lib_ext/**/*.rb", __FILE__)).each do |file|
  require file
end
