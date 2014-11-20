require 'find'
require 'fileutils'
require 'set'
require "#{File.dirname(__FILE__)}/common_buildfile.rb"

define 'Dev-Build' do

APP_CONTAINED_PROJECT = '-app'
ATG_HOME = Buildr.settings.user['atg']['home']
BUILD_FILE = 'buildfile_dev.rb'


artifact_mapping = Hash[
'Common' => 'Common',
'Web'    => 'Web',
'Fulfillment'  => 'Fulfillment',
'KF_Publishing' => 'Publishing',
'KF_Agent'  =>  'Agent',
'Staging'   =>  'Staging',
'SiteBuilderCIMInstall'   =>  'SiteBuilderCIMInstall'
]

##=================================================



modules = Buildr.settings.profile['modules']


def profile_all?
  Buildr.environment == 'all'
end

if ! modules && profile_all?
  profiles = Buildr.settings.profiles
  paths = Set.new
  profiles.each_key do |key|
    if profiles[key].has_key? 'modules'
      profiles[key]['modules'].each do |mod|
        paths << mod
      end
    end
  end
modules = paths.to_a
end


if ! modules && ARGV.last && (ARGV.last.include?('/') || ARGV.last.include?('\\'))
  arg = ARGV.pop
  module_name = nil
  artifact_mapping.each_pair do |key, val|
    unless module_name
      module_name = arg.gsub(val, key)
      module_name = module_name.gsub('/', '_')
      module_name = module_name.gsub('\\', '_')
      if module_name.rindex('_') == module_name.length
      module_name = module_name[1,-2]
      end
      modules = [module_name]
    end
  end
end


unless modules
  
  valid_modules = 'Please specify one of existing profiles (e.g. buildr -e <module>): '
  profiles = Buildr.settings.profiles
  
  profiles.each_key do |key|
    valid_modules += "#{key} "
  end
  puts
  puts valid_modules
  puts
  exit
end


start_directory = Dir.pwd
directories_to_build = []
modules_in_dirs = []
dirs_to_modules = {}

modules.each do |mod|
  dirs = mod.split('_')
  target_dir = start_directory
  module_dir = ''
  dirs.each do |dir|
    module_dir += "/#{artifact_mapping.key?(dir) ? artifact_mapping[dir] : dir }"
  end
  target_dir += module_dir

  if File.file? ".#{module_dir}/#{BUILD_FILE}"
    modules_in_dirs.push module_dir
    directories_to_build.push target_dir
    dirs_to_modules[target_dir] = mod
    puts mod
  end
end

puts '        Going to build modules within next folders:'
puts modules_in_dirs

command = ''
ARGV.each do |arg|
  command += "#{arg} "
end


command = command.strip
curr_dir = Dir.pwd
directories_to_build.each do |dir|

  Dir.chdir dir
  puts "Executing #{command} within #{dir}"  
  res = system "buildr -f #{BUILD_FILE} #{command}" 
  
  unless res
   exit
  end

end
Dir.chdir start_directory

end
