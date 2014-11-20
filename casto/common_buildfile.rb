require 'sfxutil/ext/atg_name_space'
require "#{File.dirname(__FILE__)}/env-install/deps/atg.rb"
require "#{File.dirname(__FILE__)}/env-install/deps/kf_deps.rb"

if ENV['UPLOAD_REPOSITORY']
  repositories.release_to[:url] = ENV['UPLOAD_REPOSITORY']
  puts "Is about to change upload repository to #{repositories.release_to[:url]}"
end

ARGV.each do |a|
  if a.match(/^emma/)
    require 'sfxutil/ext/emma'
  end
  if a.match(/^pmd/)
    require 'sfxutil/ext/pmd'
  end
  if a.match(/^jdepend/)
    require 'sfxutil/ext/kf/jdepend'
  end
  if a.match(/^fb:/)
    require 'sfxutil/ext/findbugs'
  end
  if a.match(/^jboss:deploy/)
    require 'sfxutil/ext/kf/deploy'
  end
  if a.match(/^sonar/)
    require 'sfxutil/ext/kf/sonar'
  end
  if a.match(/^upload_ver/)
    require 'sfxutil/ext/kf/upload_ver'
  end
end


def exclude_packages packages
  ARGV.each do |a|
    if a.match(/^emma/)
      packages.each do |pkg|
        emma.exclude pkg
      end
    end
  end
end

def apply_manifest project, attrs={}
  manifest_data = {
      'ATG-Product'=>"#{project.group}_#{project.name}_#{project.version}",
      'Manifest-Version'=>'1.0',
      'ATG-Client-Class-Path'=>'lib/classes.jar',
      'ATG-Class-Path'=>'lib/classes.jar @module_lib_class_path@',
      'ATG-Config-Path'=>'config/config.jar',
      'ATG-Version'=> "#{ATG_VERSION}"
    }
    if attrs
      attrs.each_pair do |key, val|
        manifest_data[key] = val
      end
    end
    project.manifest = manifest_data
    manifest_data
end
