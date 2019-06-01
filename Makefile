dependencies:
	bash install.sh
	carthage bootstrap

carthage: carthage_update install_deps

carthage_update:
	carthage update --platform iOS

install_deps:
	ruby install_carthage.rb
