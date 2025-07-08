buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.huaweicloud.com/repository/google/") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
