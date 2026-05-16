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

subprojects {
    val project = this
    if (project.state.executed) {
        configureAndroid(project)
    } else {
        project.afterEvaluate {
            configureAndroid(project)
        }
    }
}

fun configureAndroid(project: Project) {
    if (project.name == "app") {
        return
    }
    if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
        try {
            val android = project.extensions.getByName("android")
            // Use reflection to set compileSdkVersion to avoid classpath dependency on BaseExtension
            try {
                val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                if (project.name == "installed_apps") {
                    method.invoke(android, 34)
                    println("SUCCESS: Set compileSdkVersion to 34 for ${project.name}")
                } else {
                    method.invoke(android, 36)
                    println("SUCCESS: Set compileSdkVersion to 36 for ${project.name}")
                }
            } catch (e: Exception) {
                 try {
                     val method = android.javaClass.getMethod("compileSdkVersion", String::class.java)
                     if (project.name == "installed_apps") {
                         method.invoke(android, "android-34")
                         println("SUCCESS: Set compileSdkVersion to android-34 for ${project.name}")
                     } else {
                         method.invoke(android, "android-36")
                         println("SUCCESS: Set compileSdkVersion to android-36 for ${project.name}")
                     }
                 } catch (e2: Exception) {
                     println("Failed to set compileSdkVersion for ${project.name}: ${e} | ${e2}")
                 }
            }
        } catch (e: Exception) {
             println("Failed to access android extension for ${project.name}: ${e}")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
