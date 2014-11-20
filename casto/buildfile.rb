require 'find'
require 'set'
require "#{File.dirname(__FILE__)}/common_buildfile.rb"

APP_CONTAINED_PROJECT = '-app'
BUILD_FILE = 'buildfile.rb'

artifact_mapping = Hash[
'kf' => 'kingfisher',
'tp' => 'tradepoint',
'cc' => 'agent'
]

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
  puts
  puts 'Please specify one of existing profiles e.g.: comm, tpm, tpa, pubm, puba, ccm, cca, ffm, ffa'
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

def sync_targets
  eclipse_command = 'production'
  eclipse_command
end

command = command.strip
curr_dir = Dir.pwd
directories_to_build.each do |dir|
  eclipse_command = '' 
  if ARGV.include? 'eclipse'
  
    pub_app = 'kf-versioned-publishing-app'
    tp_app = 'tp-tradepoint-app'
    cc_app = 'agent-app'
    
    if Buildr.settings.profiles['comm']['modules'].include?(dirs_to_modules[dir])
      eclipse_command = "apps=#{tp_app},#{pub_app},#{cc_app} servers=#{sync_targets},publishing,agent"
    elsif Buildr.settings.profiles['tpm']['modules'].include? dirs_to_modules[dir]
      eclipse_command = "apps=#{tp_app} servers=#{sync_targets}"
    elsif Buildr.settings.profiles['pubm']['modules'].include? dirs_to_modules[dir]
      eclipse_command = "apps=#{pub_app} servers=publishing"
    elsif Buildr.settings.profiles['ccm']['modules'].include? dirs_to_modules[dir]
      eclipse_command = "apps=#{cc_app} servers=agent"
    end
  end

  Dir.chdir dir
  trace "Executing #{command} #{eclipse_command} within #{dir}"
  puts eclipse_command if eclipse_command != ''
  
  if profile_all?
    res = system "buildr #{command} #{eclipse_command}" 
  else
    res = system "ruby #{curr_dir}/jbuildr.rb #{command} #{eclipse_command}"
  end
  
  unless res
    exit
  end
end
Dir.chdir start_directory
