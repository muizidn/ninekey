require 'xcodeproj'

$current_directory_name = File.basename(Dir.getwd)
$project_path = "./#{$current_directory_name}.xcodeproj"
$project = Xcodeproj::Project.open($project_path)
$frameworks = Dir.glob('Carthage/Build/iOS/*.framework')

module Constant
  class << self
    attr_accessor :inherited, :carthage_path , :root, :build_product_carthage_folder_path
  end
  self.inherited = "$(inherited)"
  self.carthage_path = "$(PROJECT_DIR)/Carthage/Build/iOS"
  self.root = "$(SRCROOT)/"
  self.build_product_carthage_folder_path = "$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/"
end

# Script Phase
def input_framework_files
  $frameworks.map do | fw |
    Constant.root + fw
  end
end

def output_framework_files
  $frameworks.map do | fw |
    Constant.build_product_carthage_folder_path + fw
  end
end

def add_carthage_build_phase(target)
  puts 'New shell script build phase: Carthage'

  phase = target.shell_script_build_phases.find { |e| e.name == "Carthage" }
  phase = phase || target.new_shell_script_build_phase("Carthage")

  script = "/usr/local/bin/carthage copy-frameworks"

  puts "  Script: #{script}"

  phase.shell_script = script

  phase.input_paths = []
  input_framework_files.each.with_index do | f, i |
    puts "\e[96m" + "  Input file #{i} : #{f}" + "\e[0m"
    phase.input_paths.push(f)
  end

  phase.output_paths = []
  output_framework_files.each.with_index do | f, i |
    puts "\e[32m" + "  Output file #{i} : #{f}" + "\e[0m"
    phase.output_paths.push(f)
  end
end

# Link Binary with Libraries
def link_binary_with_libraries_phase(target)
  puts "Link binary with libraryes"
  phase = target.build_phases.find { |phase| phase.is_a?(Xcodeproj::Project::Object::PBXFrameworksBuildPhase) }
  $frameworks.each do | fw |
    file_ref = Xcodeproj::Project::Object::PBXFileReference.new($project, $project.generate_uuid)
    file_ref.path = fw
    file_ref.source_tree = "<group>"
    file_ref.last_known_file_type = "wrapper.framework"
    file_ref.name = /.*\/(.*)\.framework/.match(fw)[1]
    phase.add_file_reference(file_ref, true)
  end
end

# Update Framework Search Path
def update_framework_search_path(target)
  puts "Update framework search path"
  target.build_configurations.each do | config |
    framework_search_path = config.build_settings["FRAMEWORK_SEARCH_PATHS"]
    fsp = framework_search_path || Set.new
    fsp = fsp.to_set
    fsp.add(Constant.inherited)
    fsp.add(Constant.carthage_path)
    config.build_settings["FRAMEWORK_SEARCH_PATHS"] = fsp.to_a
  end
end

$project.targets.each do | target |
  if target.name == $current_directory_name
    puts "Use target #{target.name}"
    add_carthage_build_phase target
    link_binary_with_libraries_phase target
    update_framework_search_path target
  end
end

$project.save($project_path)
puts "\e[91m" + "Please close then reopen your project if new script not displayed" + "\e[0m"
sleep(2)
system("open #{$current_directory_name}.xcworkspace")