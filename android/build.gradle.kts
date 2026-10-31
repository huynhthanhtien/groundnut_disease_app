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

// Some plugins (e.g. tflite_flutter) don't pin their own JVM target and end
// up inheriting mismatched defaults for their Java vs Kotlin compile tasks
// when built with a newer host JDK: their own build.gradle sets
// compileOptions explicitly (overriding a plugins.withId-based fix applied
// too early), so this must run in afterEvaluate to win. :app is skipped
// because evaluationDependsOn(":app") above forces it to fully evaluate
// before this block's afterEvaluate can attach to it (it already has the
// correct 17/17 target set directly in app/build.gradle.kts anyway).
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
