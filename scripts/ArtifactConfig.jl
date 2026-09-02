module ArtifactConfig

export EXPORT_TARGETS, LIVE_NOTEBOOKS, PACKAGE_NAME, ZIP_FILENAME

const PACKAGE_NAME = "LowRankStructureIsGeometry-public"
const ZIP_FILENAME = "$PACKAGE_NAME.zip"

const EXPORT_TARGETS = [
    (source = "notebooks/00_Primer.jl", output = "html/00_Primer.html", static_notice = true),
    (source = "notebooks/01_OneObjectManyCoordinates.jl", output = "html/01_OneObjectManyCoordinates.html", static_notice = true),
    (source = "notebooks/02_GeometryAtlas.jl", output = "html/02_GeometryAtlas.html", static_notice = true),
    (source = "notebooks/03_OptimizationFailureMuseum.jl", output = "html/03_OptimizationFailureMuseum.html", static_notice = true),
    (source = "notebooks/04_NeuralRepresentations.jl", output = "html/04_NeuralRepresentations.html", static_notice = true),
    (source = "notebooks/05_ExerciseSheet.jl", output = "html/05_ExerciseSheet.html", static_notice = false),
    (source = "appendix/GlossaryAppendix.jl", output = "html/GlossaryAppendix.html", static_notice = false),
    (source = "slides/TensorKitchen_Interactive_Intro_Deck.jl", output = "slides/TensorKitchen_Interactive_Intro_Deck.html", static_notice = false),
]

const LIVE_NOTEBOOKS = [
    "notebooks/00_Primer.jl",
    "notebooks/01_OneObjectManyCoordinates.jl",
    "notebooks/02_GeometryAtlas.jl",
    "notebooks/03_OptimizationFailureMuseum.jl",
    "notebooks/04_NeuralRepresentations.jl",
]

end
