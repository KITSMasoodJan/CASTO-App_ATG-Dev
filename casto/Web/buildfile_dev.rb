require 'sfxutil/ext/atg_name_space'
require 'sfxutil/manifest_processor'
require 'sfxutil/file_processor'
require 'kfutil/dev_deploy'
load_common_buildfile
require 'build_deps'

define 'Web' do

##========= Project Specific ==================================================   

  ATG_HOME = Buildr.settings.user['atg']['home']
  BASE_ATG_FOLDER = "KF"
  MODULE_ATG_FOLDER = "Web"

  project.version = WEB_VERSION
  project.group = WEB_MODULES_GROUP

  compile.with(ATG_MODULES, EXTERNALS_MODULES, KF_SERVICES_CARRIER_BOOKING)
  
  test.using :java_args => [ '-Xms512m', '-Xmx768m', '-XX:PermSize=256m', '-XX:MaxPermSize=256m' ]
  test.compile.with(ATG_MODULES, EXTERNALS_MODULES, KF_SERVICES_CARRIER_BOOKING)
  test.with(ATG_MODULES, EXTERNALS_MODULES, KF_SERVICES_CARRIER_BOOKING)

  ## We want to use the projects compiled classes and not the jar from the maven repo!
  ## These dependecies need to be kept up to date manually - since the buildr project files are not aware of each other
  ## so using buildr project dependencies for compiled classes is not possible e.g compile.with project("Common-XXX")

  compile.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Validation/lib/classes.jar"]
  compile.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-API/lib/classes.jar"]
  compile.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Base/lib/classes.jar"]
  compile.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Messaging/lib/classes.jar"]
  
  target_folder = FileUtils.mkdir_p("#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Validation/lib/classes.jar/atg/process")
   Dir.chdir(target_folder) do
     FileUtils.touch('ProcessResources.properties')
     FileUtils.touch('ProcessTypeSpecificResources.properties')
   end

  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Validation/lib/classes.jar"]
  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Validation/lib/resources.jar"]
  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-API/lib/classes.jar"]
  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-API/lib/resources.jar"]
  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Base/lib/classes.jar"]
  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Base/lib/resources.jar"]
  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Messaging/lib/classes.jar"]  
  test.with Dir["#{ATG_HOME}/#{BASE_ATG_FOLDER}/Common-Messaging/lib/resources.jar"]  

  package(:zip).tap do |zpack|
      zpack.path('/sitemap')
      zpack.path('casto-app/css').include('src/j2ee/storefront.war/casto-app/css/*')
      zpack.path('casto-app/js').include('src/j2ee/storefront.war/casto-app/js/*')
      zpack.path('casto-app/img').include('src/j2ee/storefront.war/casto-app/img/*')
      zpack.path('casto-app/images').include('src/j2ee/storefront.war/casto-app/images/*')
      zpack.path('casto-app/foresee').include('src/j2ee/storefront.war/casto-app/foresee/*')
      zpack.path('casto-app/maintenance').include('src/j2ee/storefront.war/casto-app/maintenance/*')
      zpack.path('casto-app/error').include('src/j2ee/storefront.war/casto-app/error/*')
  end
  

  ## Remember that if you are defining an array of dependencies - you will need to split the array for the classpath in atg - look at the join below
  manifest_data = [
    'ATG-Product'=>"#{project.group}_#{project.name}_#{project.version}",
    'Manifest-Version'=>'1.0',
    'ATG-Client-Class-Path'=>'lib/classes.jar lib/resources.jar',
    'ATG-Class-Path'=>'lib/classes.jar lib/resources.jar @module_lib_class_path@',
    'ATG-Config-Path'=>'config/config.jar',
    'ATG-Required'=>'KF.Common-Messaging',
    'ATG-J2EE' => 'j2ee/storefront.war j2ee/casto.war',
    'ATG-Web-Module' => 'j2ee/casto.war',    
    'ATG_RUNTIME_DEPENDENCIES'=>"###{COMMONS_IO}## ###{JSCH}## ###{DWR}## ##" + BV_SEO.join('## ##') + "##",
    'ATG-Version'=> "#{ATG_VERSION}"

  ]

  build do
  ##======== Dev_Deployer (Common across all modules) ============================================================

   dev_deployer = Kingfisher::DevDeploy.new
   dev_deployer.dev_deploy(ATG_HOME, BASE_ATG_FOLDER, MODULE_ATG_FOLDER, manifest_data)

  ##========= Assemble this web-app (Custom per app) =============================================================

   dev_deployer.assemble_ear("DafEar.Admin DAF.Search.Base.QueryConsole DAF.Search.LiveIndex DAF.Search.Routing DAS.WebServices DCS DCS.PublishingAgent DCS.AbandonedOrderServices DCS.Search DPS.WebServices Store.EStore.International Store.Search.International.Query DAF.Search.Index DPS DSS SiteBuilder SiteBuilder.BlockLibrary KF.Common-Validation KF.Common-API KF.Common-Base KF.Web Casto.Web", "casto-web.ear")
  
  end

end
