pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Standard repositories for Gradle plugins
        google()
        mavenCentral()
        gradlePluginPortal()
        // Your regional mirrors
        maven { url = uri("https://maven.huaweicloud.com/repository/google/") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        // Standard repositories for project dependencies
        google()
        mavenCentral()
        // Your regional mirrors
        maven { url = uri("https://maven.huaweicloud.com/repository/google/") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }
}

rootProject.name = "fadeu"
include(":app")
