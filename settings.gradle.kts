pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}
//dependencyResolutionManagement {
//    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
//    repositories {
//        google()
//        mavenCentral()
//    }
//}
//rootProject.name = "AppXNetworking"
include(":app")
include(":core:basic")
include(":core:sorawallet")
include(":core:fearlesswallet")