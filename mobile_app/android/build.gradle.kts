allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    // Mengatur konfigurasi tanpa menunggu afterEvaluate
    plugins.withId("com.android.library") {
        val extension = project.extensions.getByType<com.android.build.gradle.LibraryExtension>()
        if (project.name == "flutter_bluetooth_serial") {
            extension.namespace = "io.github.edufolly.flutterbluetoothserial"
        }
    }
}
