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

    afterEvaluate {
        val project = this
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                // Use reflection to set namespace for legacy plugins that miss it (AGP 8.0+ requirement)
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val namespace = getNamespace.invoke(android)
                
                if (namespace == null) {
                    val packageName = when (project.name) {
                        "telephony" -> "com.shounakmulay.telephony"
                        else -> project.group.toString()
                    }
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, packageName)
                    println("Injected namespace '$packageName' for project '${project.name}'")
                }
            } catch (e: Exception) {
                // Ignore errors if method doesn't exist or other issues
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
