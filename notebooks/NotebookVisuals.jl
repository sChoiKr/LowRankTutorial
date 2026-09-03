module NotebookVisuals

using LinearAlgebra
using Printf
using TensorKitchen

export ai_geometry_bridge_visual,
       btd_structure_inspector,
       cancellation_warmup_visual,
       capacity_fit_visual,
       component_collision_visual,
       cp_component_inspector,
       cp_equivalence_puzzle_visual,
       decomposition_illustration,
       failure_comparison_visual,
       failure_map_visual,
       flatten_vs_tensor_visual,
       gauge_dial_visual,
       geometry_race_visual,
       gram_condition_visual,
       mode_mechanics_visual,
       model_language_visual,
       nonnegative_constraint_visual,
       running_tensor_card,
       solver_race_visual,
       swamp_microscope_visual,
       tensor_reconstruction_gallery,
       tensor_slices_visual,
       tucker_structure_inspector,
       trajectory_visual

include("VisualCore.jl")
include("00_PrimerVisuals.jl")
include("01_OneObjectManyCoordinatesVisuals.jl")
include("02_GeometryAtlasVisuals.jl")
include("03_OptimizationFailureMuseumVisuals.jl")

end
