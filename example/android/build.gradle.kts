plugins {
    // apply any plugins if needed, like kotlin("jvm") or others
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure custom build directory
val newBuildDir = layout.buildDirectory.dir("../../build")

subprojects {
    layout.buildDirectory.set(newBuildDir.map { it.dir(name) })
    evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(layout.buildDirectory)
}
