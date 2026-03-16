allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

fun packageFromManifest(project: Project): String? {
    val manifestFile = project.file("src/main/AndroidManifest.xml")
    if (!manifestFile.exists()) {
        return null
    }

    val manifestText = manifestFile.readText()
    val match = Regex("""package\s*=\s*"([^"]+)"""").find(manifestText)
    return match?.groupValues?.getOrNull(1)
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
    afterEvaluate {
        if (!plugins.hasPlugin("com.android.library")) {
            return@afterEvaluate
        }

        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val getNamespace = androidExt.javaClass.methods.find { it.name == "getNamespace" }
        val setNamespace = androidExt.javaClass.methods.find {
            it.name == "setNamespace" && it.parameterTypes.size == 1
        }

        if (getNamespace == null || setNamespace == null) {
            return@afterEvaluate
        }

        val currentNamespace = getNamespace.invoke(androidExt) as? String
        if (!currentNamespace.isNullOrBlank()) {
            return@afterEvaluate
        }

        val fallbackNamespace = packageFromManifest(this)
        if (!fallbackNamespace.isNullOrBlank()) {
            setNamespace.invoke(androidExt, fallbackNamespace)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
