module GlossaryContent

export GLOSSARY_ENTRIES, GLOSSARY_REFERENCES, CLUSTER_ORDER

const RAW_MATH_GLOSSARY = [
    (term="Tensor", category="Mathematics", definition="A multidimensional array \$\\mathcal X\\in\\mathbb R^{n_1\\times\\cdots\\times n_d}\$. A matrix is the order-2 case.", tutorial="The notebooks preserve meaningful modes instead of always flattening them.", reading="Kolda & Bader (2009)", related=["Mode", "Matricization", "CP decomposition", "Tucker decomposition"]),
    (term="Mode", category="Mathematics", definition="One axis of a tensor.", tutorial="A mode may represent samples, spatial positions, features, time, or another scientifically meaningful variable class.", reading="Kolda & Bader (2009)", related=["Tensor", "Matricization", "Multilinear rank"]),
    (term="Matricization / unfolding", category="Mathematics", definition="A rearrangement of a tensor into a matrix by choosing one or more modes as matrix axes.", tutorial="Flattening can enable matrix methods while merging distinct mode semantics.", reading="Kolda & Bader (2009)", related=["Mode", "SVD", "Tucker decomposition"]),
    (term="Outer product", category="Mathematics", definition="For vectors \$a,b,c\$, the tensor \$a\\otimes b\\otimes c\$ has entries \$(a\\otimes b\\otimes c)_{ijk}=a_i b_j c_k\$.", tutorial="Every CP rank-one term is an outer product of one vector from each mode.", reading="Kolda & Bader (2009)", related=["Rank-one tensor", "CP decomposition"]),
    (term="Rank-one tensor", category="Mathematics", definition="A tensor that can be written as one outer product \$a^{(1)}\\otimes\\cdots\\otimes a^{(d)}\$.", tutorial="It is the basic component of CP decomposition and the Segre model.", reading="Kolda & Bader (2009); Breiding & Vannieuwenhoven (2018)", related=["Outer product", "Segre manifold / variety", "CP decomposition"]),
    (term="Matrix rank", category="Mathematics", definition="The dimension of the column space (equivalently, row space) of a matrix.", tutorial="Matrix rank should not be confused with CP rank or multilinear rank.", reading="Standard linear algebra", related=["CP rank", "Multilinear rank", "Fixed-rank manifold"]),
    (term="CP decomposition", category="Mathematics", definition="A model \$\\mathcal X\\approx\\sum_{r=1}^R\\lambda_r a_r^{(1)}\\otimes\\cdots\\otimes a_r^{(d)}\$.", tutorial="CP is the main example where factor vectors are coordinates while the reconstructed tensor is the represented object.", reading="Kolda & Bader (2009); Breiding & Vannieuwenhoven (2018)", related=["CP rank", "Factor matrix", "Scaling ambiguity", "Permutation ambiguity"]),
    (term="CP rank", category="Mathematics", definition="The smallest number of rank-one tensors whose sum equals a tensor exactly.", tutorial="It differs from matrix rank and Tucker multilinear rank.", reading="Kolda & Bader (2009)", related=["Rank-one tensor", "CP decomposition", "Multilinear rank"]),
    (term="Factor matrix", category="Mathematics", definition="In CP, vectors from one mode are collected as columns of a factor matrix.", tutorial="Its columns are coordinates and can change under CP scaling or permutation equivalences.", reading="Kolda & Bader (2009)", related=["CP decomposition", "Coordinates vs represented object", "Scaling ambiguity"]),
    (term="Tucker decomposition", category="Mathematics", definition="A model \$\\mathcal X\\approx\\mathcal G\\times_1U_1\\times_2\\cdots\\times_dU_d\$ with a core tensor and mode factors.", tutorial="Tucker emphasizes mode-wise subspaces and their interactions rather than a sum of rank-one terms.", reading="De Lathauwer, De Moor & Vandewalle (2000); Kolda & Bader (2009)", related=["Core tensor", "Multilinear rank", "HOSVD", "Subspace"]),
    (term="Core tensor", category="Mathematics", definition="The smaller tensor \$\\mathcal G\$ in a Tucker representation that records interactions among selected mode coordinates.", tutorial="Individual core entries are basis-dependent; the mode subspaces can be more invariant than a particular basis.", reading="Kolda & Bader (2009)", related=["Tucker decomposition", "Gauge freedom / equivalence"]),
    (term="Multilinear rank", category="Mathematics", definition="The tuple \$(r_1,\\ldots,r_d)\$ of ranks of the tensor's mode unfoldings.", tutorial="It is the rank notion naturally associated with Tucker models.", reading="De Lathauwer, De Moor & Vandewalle (2000)", related=["Tucker decomposition", "HOSVD", "Matrix rank"]),
    (term="HOSVD", category="Mathematics", definition="Higher-Order SVD constructs Tucker mode subspaces from singular vectors of tensor unfoldings.", tutorial="It gives an operational way to inspect multilinear rank and compress a tensor.", reading="De Lathauwer, De Moor & Vandewalle (2000)", related=["Tucker decomposition", "Multilinear rank", "SVD"]),
    (term="Block-Term Decomposition / BTD", category="Mathematics", definition="A sum of structured multilinear-rank blocks rather than only rank-one terms.", tutorial="A BTD component can represent within-component interactions that are not separable across modes.", reading="De Lathauwer (2008)", related=["Tucker decomposition", "CP decomposition", "Multilinear rank"]),
    (term="SVD", category="Mathematics", definition="For a matrix \$X\$, \$X=U\\Sigma V^\\top\$.", tutorial="It provides an optimal low-rank approximation for a chosen matricization but can merge mode semantics after flattening.", reading="Standard linear algebra; Kolda & Bader (2009)", related=["Matrix rank", "Matricization / unfolding", "Subspace"]),
    (term="Subspace", category="Mathematics", definition="A subset of a vector space closed under addition and scalar multiplication.", tutorial="Low-rank matrix and Tucker methods often identify a subspace more naturally than an individually meaningful basis vector.", reading="Standard linear algebra; Absil, Mahony & Sepulchre (2008)", related=["Orthonormal basis", "Stiefel manifold", "Subspace learning"]),
    (term="Orthonormal basis", category="Mathematics", definition="A basis whose vectors have unit norm and are mutually orthogonal.", tutorial="An orthonormal matrix is a convenient coordinate system for a subspace, but different bases can span the same subspace.", reading="Standard linear algebra", related=["Subspace", "Stiefel manifold", "Gauge freedom / equivalence"]),
    (term="Manifold", category="Mathematics", definition="A space that locally resembles Euclidean space and supports tangent-space calculus.", tutorial="Several low-rank model spaces are naturally treated as manifolds for optimization.", reading="Absil, Mahony & Sepulchre (2008)", related=["Tangent space", "Retraction", "Riemannian optimization"]),
    (term="Stiefel manifold", category="Mathematics", definition="\$\\mathrm{St}(n,r)=\\{U\\in\\mathbb R^{n\\times r}:U^\\top U=I_r\\}\$, the set of matrices with orthonormal columns.", tutorial="It appears when learning orthonormal bases or subspace coordinates, as in StelLA.", reading="Absil, Mahony & Sepulchre (2008); Li et al. (2025)", related=["Subspace", "Orthonormal basis", "Subspace learning"]),
    (term="Segre manifold / variety", category="Mathematics", definition="The geometric model of rank-one tensors obtained from outer products.", tutorial="A CP tensor is a sum of Segre components.", reading="Breiding & Vannieuwenhoven (2018)", related=["Rank-one tensor", "CP decomposition", "Riemannian optimization"]),
    (term="Fixed-rank manifold", category="Mathematics", definition="The smooth manifold of matrices having a fixed rank, away from rank-changing boundaries.", tutorial="It allows direct optimization of a low-rank matrix object without introducing a redundant factorization.", reading="Absil, Mahony & Sepulchre (2008); Bian et al. (2025)", related=["Matrix rank", "Factorized parameterization", "Parameter redundancy"]),
    (term="Coordinates vs represented object", category="Mathematics", definition="A parameterization gives coordinates to an object; different coordinates may represent exactly the same object.", tutorial="This is the central distinction of the tutorial: factors are coordinates, while the reconstructed matrix or tensor is the object.", reading="Labs 1–4; Breiding & Vannieuwenhoven (2018)", related=["Gauge freedom / equivalence", "Identifiability", "Factor matrix"]),
    (term="Gauge freedom / equivalence", category="Mathematics", definition="A family of coordinate transformations that leaves the represented object unchanged.", tutorial="Examples include matrix basis changes and Tucker basis changes absorbed by the core.", reading="Standard low-rank matrix and tensor literature", related=["Coordinates vs represented object", "Scaling ambiguity", "Permutation ambiguity"]),
    (term="Scaling ambiguity", category="Mathematics", definition="A reciprocal rescaling of factors can preserve the same rank-one tensor, e.g. \$(\\alpha a)\\otimes(\\beta b)\\otimes((\\alpha\\beta)^{-1}c)\$.", tutorial="Factor norms can change substantially while reconstruction stays unchanged.", reading="Kolda & Bader (2009)", related=["CP decomposition", "Gauge freedom / equivalence"]),
    (term="Permutation ambiguity", category="Mathematics", definition="Reordering CP components does not change their sum.", tutorial="Two CP outputs should be aligned before column-by-column comparison.", reading="Kolda & Bader (2009)", related=["CP decomposition", "Identifiability"]),
    (term="Identifiability", category="Mathematics", definition="A model is identifiable when the represented object determines its parameters uniquely after accepted equivalences are accounted for.", tutorial="Identifiability is necessary for literal coordinate recovery, but a mathematically identifiable factor is not automatically a scientifically meaningful concept.", reading="Kolda & Bader (2009); De Lathauwer (2008)", related=["Coordinates vs represented object", "Semantic validation", "Stability"]),
    (term="Conditioning", category="Mathematics", definition="Sensitivity of a solution or representation to small perturbations of the input or represented object.", tutorial="A low reconstruction error can coexist with unstable component coordinates.", reading="Breiding & Vannieuwenhoven (2018)", related=["Condition number", "Component collision", "Stability"]),
    (term="Condition number", category="Mathematics", definition="A numerical quantity that measures sensitivity; for nonsingular \$M\$, one common form is \$\\kappa(M)=\\|M\\|\\|M^{-1}\\|\$.", tutorial="Different condition numbers diagnose different objects; ALS subproblem conditioning and geometric CP conditioning should not be conflated.", reading="Standard numerical linear algebra; Breiding & Vannieuwenhoven (2018)", related=["Conditioning", "ALS", "Component collision"]),
    (term="Relative reconstruction error", category="Mathematics", definition="\$\\|X-\\widehat X\\|_F/\\|X\\|_F\$ (and analogously for tensors).", tutorial="It measures object-level fit, not uniqueness, stability, or semantic validity.", reading="Kolda & Bader (2009)", related=["Reconstruction", "Stability", "Semantic validation"]),
    (term="Nonconvex optimization", category="Mathematics", definition="Optimization in which the objective or feasible set does not have global convexity guarantees.", tutorial="Low-rank factorizations can have initialization-dependent trajectories and multiple stationary regions.", reading="Standard optimization literature", related=["Initialization", "ALS", "Riemannian optimization"]),
    (term="Initialization", category="Mathematics", definition="The starting coordinates or starting low-rank object supplied to an iterative solver.", tutorial="Different starts can produce different optimization trajectories even for the same target and model.", reading="Kolda & Bader (2009)", related=["Nonconvex optimization", "Stability", "Swamp / swamp-like stagnation"]),
    (term="Overparameterization / excessive rank", category="Mathematics", definition="Using more latent components than are needed to represent the dominant structure.", tutorial="Extra components can split or duplicate structure and complicate interpretation.", reading="General low-rank modeling background", related=["Rank choice", "Feature splitting", "Component collision"]),
    (term="Rank choice", category="Mathematics", definition="The selected number of components or latent dimensions used by a model.", tutorial="Rank controls both approximation capacity and the granularity of the learned vocabulary.", reading="Labs 2 and 4", related=["Overparameterization / excessive rank", "Concept granularity", "Model mismatch"]),
    (term="ALS", category="Mathematics", definition="Alternating Least Squares updates one factor block at a time while keeping the others fixed.", tutorial="It is simple and effective, but its local least-squares systems can become poorly conditioned.", reading="Kolda & Bader (2009)", related=["Condition number", "RALS", "Regularized ALS", "Swamp / swamp-like stagnation"]),
    (term="RALS", category="Mathematics", definition="Randomized Alternating Least Squares approximates ALS block updates using sampled rows of the Khatri-Rao least-squares problem.", tutorial="In TensorKitchen v0.2.0, `RALSSolver` implements Randomized CP-ALS (CPRAND/CPRAND-MIX); it is not the ridge-regularized teaching solver used in Lab 3.", reading="TensorKitchen documentation; tensor optimization literature", related=["ALS", "Regularized ALS"]),
    (term="Regularized ALS", category="Mathematics", definition="Regularized ALS adds a penalty or stabilizing term, such as a ridge term, to alternating least-squares subproblems.", tutorial="Lab 3 uses a small ridge-regularized ALS implementation to study conditioning. It is distinct from TensorKitchen's randomized `RALSSolver`.", reading="Tensor optimization literature; Lab 3", related=["ALS", "RALS", "Conditioning"]),
    (term="Riemannian optimization", category="Mathematics", definition="Optimization performed on a manifold using tangent-space gradients and manifold-compatible updates.", tutorial="It respects the geometry of low-rank model spaces instead of treating all coordinates as unconstrained Euclidean parameters.", reading="Absil, Mahony & Sepulchre (2008)", related=["Manifold", "Tangent space", "Retraction", "RGD"]),
    (term="Tangent space", category="Mathematics", definition="The linear space of infinitesimal feasible directions at a point on a manifold.", tutorial="Riemannian gradients and search directions live in tangent spaces.", reading="Absil, Mahony & Sepulchre (2008)", related=["Manifold", "Retraction", "Riemannian optimization"]),
    (term="Retraction", category="Mathematics", definition="A map that sends a tangent-space step back to the manifold and agrees locally with the manifold geometry.", tutorial="It turns a tangent search direction into a new feasible point.", reading="Absil, Mahony & Sepulchre (2008)", related=["Tangent space", "RGD", "RCG"]),
    (term="RGD", category="Mathematics", definition="Riemannian Gradient Descent follows the negative Riemannian gradient and retracts each step.", tutorial="It is a basic geometry-aware alternative to Euclidean or alternating updates.", reading="Absil, Mahony & Sepulchre (2008)", related=["Riemannian optimization", "Retraction", "RAdaGrad / RAdamW"]),
    (term="RCG", category="Mathematics", definition="Riemannian Conjugate Gradient combines the current gradient with transported information from previous directions.", tutorial="It provides a geometry-aware acceleration strategy beyond steepest descent.", reading="Absil, Mahony & Sepulchre (2008)", related=["Riemannian optimization", "RGD"]),
    (term="Levenberg–Marquardt / LM", category="Mathematics", definition="A damped Gauss–Newton-type method for nonlinear least-squares problems.", tutorial="It is a general curvature-aware strategy, but TensorKitchen v0.2.0 does not expose LM as a CPD solver.", reading="Standard nonlinear least squares", related=["Conditioning", "Nonconvex optimization"]),
    (term="Component collision", category="Mathematics", definition="Two normalized rank-one components become nearly indistinguishable as represented rank-one tensors, up to accepted scale/sign conventions.", tutorial="Collision can make component roles hard to separate and can contribute to ill-conditioned local subproblems.", reading="Lab 3; Breiding & Vannieuwenhoven (2018)", related=["Conditioning", "Degeneracy", "Swamp / swamp-like stagnation"]),
    (term="Degeneracy", category="Mathematics", definition="A tensor-approximation pathology in which component norms can grow while their sum remains bounded, often through near cancellation.", tutorial="A small represented tensor can hide large, fragile component coordinates.", reading="Kolda & Bader (2009); Breiding & Vannieuwenhoven (2018)", related=["Cancellation", "Component collision", "Conditioning"]),
    (term="Cancellation", category="Mathematics", definition="Large terms with opposing contributions combine to produce a much smaller sum.", tutorial="It is a separate pathology from component collision, even though the two may occur together.", reading="Lab 3", related=["Degeneracy", "Component collision"]),
    (term="Swamp / swamp-like stagnation", category="Mathematics", definition="An extended region of very slow objective improvement during an iterative tensor-decomposition method.", tutorial="A plateau is an observation, not an explanation: collision, degeneracy, initialization, rank choice, and model mismatch are possible contributors.", reading="Kolda & Bader (2009); Lab 3", related=["Component collision", "Initialization", "Model mismatch"]),
    (term="Model mismatch", category="Mathematics", definition="The chosen model family does not adequately represent the structure that generated the data.", tutorial="Poor fit is not always an optimization failure; the structural assumption itself may be wrong.", reading="Lab 2; standard modeling literature", related=["Rank choice", "Reconstruction", "Nonconvex optimization"])
]

const RAW_AI_GLOSSARY = [
    (term="Neural representation", category="AI & Interpretability", definition="The internal activation state produced by a neural network for an input at a chosen layer or module.", tutorial="Low-rank methods are applied to collections of such states to test hypotheses about recurring structure.", reading="Kim et al. (2018); Ghorbani et al. (2019); Fel et al. (2023)", related=["Activation", "Activation space", "Latent representation"]),
    (term="Activation", category="AI & Interpretability", definition="The numerical output of a neuron, channel, token position, or other internal unit after a layer processes an input.", tutorial="In the CRAFT-style lab, each image crop produces an activation vector.", reading="Fel et al. (2023)", related=["Neural representation", "Activation space", "Image crop / patch"]),
    (term="Activation space", category="AI & Interpretability", definition="The vector space in which a chosen layer's activation vectors live.", tutorial="CAVs, NMF directions, and SAE decoder directions can all be discussed as directions in an activation space.", reading="Kim et al. (2018); Cunningham et al. (2023)", related=["CAV", "Feature direction", "Sparse autoencoder"]),
    (term="Latent representation", category="AI & Interpretability", definition="A lower-dimensional or internal representation that is not identical to the original input.", tutorial="CP, Tucker, NMF, SVD, and autoencoders all introduce latent coordinates under different assumptions.", reading="General representation-learning literature", related=["Representation learning", "Latent code", "Dictionary learning"]),
    (term="Representation learning", category="AI & Interpretability", definition="Learning useful internal variables or coordinates from data rather than specifying all features by hand.", tutorial="The tutorial compares several structured representation families and asks what their coordinates can legitimately mean.", reading="Goodfellow, Bengio & Courville (2016)", related=["Latent representation", "Dictionary learning", "Autoencoder"]),
    (term="Feature", category="AI & Interpretability", definition="An overloaded term that may mean an input variable, neuron, activation direction, or learned latent factor.", tutorial="The tutorial avoids assuming that every learned factor is automatically a semantic feature.", reading="General interpretability literature", related=["Feature direction", "Concept", "Dictionary atom"]),
    (term="Feature direction", category="AI & Interpretability", definition="A direction in activation space associated with a recurring learned pattern.", tutorial="Dictionary atoms, CAVs, and SAE decoder columns can all be treated as candidate feature directions, with different training assumptions.", reading="Kim et al. (2018); Cunningham et al. (2023)", related=["Activation space", "Dictionary atom", "CAV"]),
    (term="Concept", category="AI & Interpretability", definition="A higher-level pattern used to describe model representations or behavior in human-relevant terms.", tutorial="A learned direction is first a candidate concept; semantic meaning requires additional evidence.", reading="Kim et al. (2018); Ghorbani et al. (2019)", related=["Concept discovery", "Semantic validation", "CAV"]),
    (term="Concept-based interpretability", category="AI & Interpretability", definition="Explaining neural networks using higher-level concepts rather than only individual input features or neurons.", tutorial="CRAFT is the main case study in Lab 4.", reading="Kim et al. (2018); Ghorbani et al. (2019); Fel et al. (2023)", related=["Concept", "TCAV", "ACE", "CRAFT"]),
    (term="Concept discovery", category="AI & Interpretability", definition="Searching for recurring structure in neural activations that may correspond to meaningful higher-level patterns, often without pre-specifying all concepts.", tutorial="Discovery yields candidate explanations, not ground-truth semantics.", reading="Ghorbani et al. (2019); Fel et al. (2023)", related=["Dictionary learning", "CRAFT", "Semantic coherence"]),
    (term="Feature attribution", category="AI & Interpretability", definition="Assigning importance scores to input features or internal variables for a model prediction.", tutorial="Concept methods address a different level of explanation by grouping behavior into higher-level directions or concepts.", reading="Ghorbani et al. (2019); Fel et al. (2023)", related=["Concept attribution", "Faithfulness"]),
    (term="Concept attribution", category="AI & Interpretability", definition="Estimating how a higher-level candidate concept contributes to a prediction.", tutorial="CRAFT combines concept discovery with concept importance and concept attribution maps.", reading="Fel et al. (2023)", related=["Concept importance", "Concept Attribution Map", "CAV"]),
    (term="Dictionary learning", category="AI & Interpretability", definition="Learning a set of reusable basis elements \$D\$ such that observations can be approximated as combinations \$x_i\\approx D\\alpha_i\$.", tutorial="It is the broader representation-learning idea behind learned feature dictionaries; NMF and sparse autoencoders impose different additional structures.", reading="Mairal et al. (2009)", related=["Dictionary atom", "Sparse coding", "NMF", "Sparse autoencoder"]),
    (term="Dictionary atom", category="AI & Interpretability", definition="One learned basis element or direction in a dictionary.", tutorial="A dictionary atom is a mathematical representation element, not automatically a validated semantic concept.", reading="Mairal et al. (2009)", related=["Dictionary learning", "Feature direction", "Semantic validation"]),
    (term="Sparse coding", category="AI & Interpretability", definition="Representing each observation with only a small number of active dictionary coefficients.", tutorial="Sparsity and nonnegativity are distinct assumptions: a code can be sparse without being nonnegative and vice versa.", reading="Mairal et al. (2009)", related=["Sparsity", "Dictionary learning", "NMF"]),
    (term="Sparsity", category="AI & Interpretability", definition="The property that most entries of a representation are zero or inactive.", tutorial="Sparse representations encourage each observation to use only a small subset of learned features.", reading="Mairal et al. (2009); Cunningham et al. (2023)", related=["Sparse coding", "Sparsity penalty", "Sparse autoencoder"]),
    (term="Sparsity penalty", category="AI & Interpretability", definition="A regularization term or constraint that encourages few active latent variables, such as an \$\\ell_1\$ penalty or related activation penalty.", tutorial="In SAEs it trades reconstruction fidelity against sparse feature usage.", reading="Sparse coding / SAE literature", related=["Sparsity", "Sparse autoencoder", "Reconstruction loss"]),
    (term="Autoencoder", category="AI & Interpretability", definition="A model trained to reconstruct an input through an intermediate latent code: \$z=f_{enc}(x)\$ and \$\\hat x=f_{dec}(z)\$.", tutorial="It provides the basic architecture from which sparse autoencoders are built.", reading="Goodfellow, Bengio & Courville (2016)", related=["Encoder", "Decoder", "Latent code", "Sparse autoencoder"]),
    (term="Encoder", category="AI & Interpretability", definition="The mapping \$f_{enc}\$ that converts an input or activation vector into latent coordinates.", tutorial="In an SAE, the encoder determines which learned latent features are active.", reading="Goodfellow, Bengio & Courville (2016); Cunningham et al. (2023)", related=["Autoencoder", "Latent code", "Decoder"]),
    (term="Decoder", category="AI & Interpretability", definition="The mapping \$f_{dec}\$ that reconstructs the input from the latent code.", tutorial="For a linear SAE decoder, decoder columns are commonly treated as learned feature directions or dictionary atoms.", reading="Cunningham et al. (2023)", related=["Autoencoder", "Dictionary atom", "Feature direction"]),
    (term="Latent code", category="AI & Interpretability", definition="The intermediate representation \$z\$ produced by an encoder.", tutorial="In an SAE, sparsity is imposed on this code so that only a small number of features activate for each input.", reading="Goodfellow, Bengio & Courville (2016)", related=["Encoder", "Sparsity", "Sparse autoencoder"]),
    (term="Sparse autoencoder / SAE", category="AI & Interpretability", definition="An autoencoder trained to reconstruct activations through a latent code that is encouraged to be sparse.", tutorial="SAEs are used in mechanistic interpretability to learn sparse feature dictionaries from neural activations; a learned SAE feature is still a candidate interpretation, not a semantic guarantee.", reading="Cunningham et al. (2023); Bricken et al. (2023); Templeton et al. (2026)", related=["Autoencoder", "Sparsity", "Dictionary learning", "Superposition"]),
    (term="Overcomplete dictionary", category="AI & Interpretability", definition="A dictionary with more learned atoms/features than the dimensionality of the input representation.", tutorial="Overcomplete feature sets are used to model the hypothesis that networks may represent more features than neurons/dimensions via superposition.", reading="Cunningham et al. (2023); Bricken et al. (2023)", related=["Superposition", "Sparse autoencoder", "Dictionary atom"]),
    (term="Feature activation", category="AI & Interpretability", definition="The coefficient or latent value indicating how strongly a learned feature is active for one example.", tutorial="High activation means presence under that representation; it does not by itself establish importance or causal relevance.", reading="SAE and concept-based interpretability literature", related=["Concept usage / coefficient", "Concept importance", "Causal relevance"]),
    (term="Dead feature / dead latent", category="AI & Interpretability", definition="A learned latent feature that rarely or never activates on the data distribution used to evaluate it.", tutorial="Dead features indicate unused dictionary capacity and are a practical SAE training diagnostic.", reading="Sparse autoencoder literature", related=["Sparse autoencoder", "Sparsity", "Feature activation"]),
    (term="Monosemanticity", category="AI & Interpretability", definition="The ideal that one learned feature corresponds to one coherent semantic pattern rather than several unrelated meanings.", tutorial="SAE work investigates whether sparse dictionaries yield more monosemantic features than individual neurons.", reading="Bricken et al. (2023); Cunningham et al. (2023); Templeton et al. (2026)", related=["Polysemanticity", "Semantic coherence", "Sparse autoencoder"]),
    (term="Polysemanticity", category="AI & Interpretability", definition="A neuron or learned feature responds to several semantically distinct patterns.", tutorial="It motivates attempts to recover cleaner latent directions than individual neurons provide.", reading="Cunningham et al. (2023); Bricken et al. (2023)", related=["Monosemanticity", "Superposition"]),
    (term="Superposition", category="AI & Interpretability", definition="The hypothesis that a network represents more features than available neurons/dimensions by encoding features in non-orthogonal directions.", tutorial="Sparse autoencoders and dictionary learning are used to search for those latent directions.", reading="Cunningham et al. (2023); Bricken et al. (2023)", related=["Overcomplete dictionary", "Polysemanticity", "Sparse autoencoder"]),
    (term="Feature splitting", category="AI & Interpretability", definition="A phenomenon where a semantic pattern that might be described as one feature at one scale is represented by several more specific learned features at another scale or model capacity.", tutorial="It warns that increasing dictionary size can change the vocabulary rather than simply refine reconstruction.", reading="SAE interpretability literature; compare Templeton et al. (2026)", related=["Rank choice", "Concept granularity", "Sparse autoencoder"]),
    (term="NMF", category="AI & Interpretability", definition="A constrained factorization \$A\\approx UW^\\top\$ with \$U,W\\ge0\$.", tutorial="In CRAFT, columns of \$W\$ are candidate concept directions and \$U_{ij}\$ measures crop-to-concept usage.", reading="Lee & Seung (1999); Fel et al. (2023)", related=["Dictionary learning", "CRAFT", "Concept bank"]),
    (term="CAV", category="AI & Interpretability", definition="A Concept Activation Vector: a direction in activation space associated with a concept.", tutorial="TCAV uses user-defined concepts; CRAFT learns candidate CAV-like directions through NMF.", reading="Kim et al. (2018); Fel et al. (2023)", related=["TCAV", "Concept", "Activation space"]),
    (term="TCAV", category="AI & Interpretability", definition="Testing with Concept Activation Vectors uses directional sensitivity in activation space to quantify relevance of user-defined concepts to predictions.", tutorial="It provides historical context for concept directions before automatic concept discovery methods such as ACE and CRAFT.", reading="Kim et al. (2018)", related=["CAV", "ACE", "Concept importance"]),
    (term="ACE", category="AI & Interpretability", definition="Automatic Concept-based Explanations automatically extracts visual concepts and evaluates their relevance to predictions.", tutorial="ACE is a key step from user-specified concepts toward automatic concept discovery.", reading="Ghorbani et al. (2019)", related=["Concept discovery", "CRAFT", "TCAV"]),
    (term="CRAFT", category="AI & Interpretability", definition="Concept Recursive Activation FacTorization for Explainability: an automatic concept method using nonnegative activation factorization, recursive decomposition, Sobol-based importance, and concept attribution maps.", tutorial="It is the main interpretability case study in Lab 4.", reading="Fel et al. (2023)", related=["NMF", "Concept bank", "Recursive concept decomposition", "Sobol sensitivity"]),
    (term="Image crop / patch", category="AI & Interpretability", definition="A local region extracted from an image and analyzed as an example.", tutorial="CRAFT-style concept discovery uses crop activations so that candidate concepts can be associated with recurring visual parts or patterns.", reading="Fel et al. (2023)", related=["Activation", "Global average pooling", "Concept discovery"]),
    (term="Global average pooling", category="AI & Interpretability", definition="Averaging a convolutional activation map over spatial positions to obtain one feature value per channel.", tutorial="CRAFT uses pooled crop activations for its NMF concept-factorization stage.", reading="Fel et al. (2023)", related=["Activation", "Image crop / patch", "Concept Attribution Map"]),
    (term="Concept bank", category="AI & Interpretability", definition="A collection of candidate concept directions used to represent or analyze activations.", tutorial="In the CRAFT-style NMF model, the columns of \$W\$ form the learned candidate concept bank.", reading="Fel et al. (2023)", related=["NMF", "CAV", "Concept usage / coefficient"]),
    (term="Concept usage / coefficient", category="AI & Interpretability", definition="A coefficient describing how strongly a candidate concept contributes to one observation's representation.", tutorial="In \$A\\approx UW^\\top\$, \$U_{ij}\$ is the usage of candidate \$j\$ by crop \$i\$.", reading="Fel et al. (2023)", related=["Concept bank", "Feature activation", "Concept importance"]),
    (term="Concept importance", category="AI & Interpretability", definition="How strongly model behavior depends on a candidate concept, rather than merely whether the concept is present.", tutorial="CRAFT estimates importance with Sobol sensitivity rather than inferring it from coefficient magnitude alone.", reading="Fel et al. (2023)", related=["Concept usage / coefficient", "Sobol sensitivity", "Causal relevance"]),
    (term="Sobol sensitivity", category="AI & Interpretability", definition="A variance-based global sensitivity measure that attributes output variation to input variables or groups.", tutorial="CRAFT applies Sobol indices to concept importance; simplified notebook meters should be labeled as pedagogical proxies unless they reproduce the full estimator.", reading="Fel et al. (2023)", related=["Concept importance", "Faithfulness"]),
    (term="Concept Attribution Map", category="AI & Interpretability", definition="A spatial map localizing evidence associated with a candidate concept in an input.", tutorial="It matters when comparing CRAFT's pooled NMF stage with tensor extensions that retain location directly.", reading="Fel et al. (2023)", related=["Concept attribution", "Global average pooling"]),
    (term="Recursive concept decomposition", category="AI & Interpretability", definition="Re-analyzing a higher-level concept using activations from an earlier layer to obtain finer sub-concepts.", tutorial="It illustrates that the semantic granularity of a concept depends on the layer.", reading="Fel et al. (2023)", related=["CRAFT", "Concept granularity", "Neural representation"]),
    (term="Concept granularity", category="AI & Interpretability", definition="The level of semantic detail expressed by a concept, from class-level structure to parts, textures, or other sub-concepts.", tutorial="Rank, layer, and representation family can all change the concept vocabulary and its granularity.", reading="Fel et al. (2023)", related=["Recursive concept decomposition", "Rank choice", "Feature splitting"]),
    (term="LoRA", category="AI & Interpretability", definition="Low-Rank Adaptation represents a trainable weight update with a low-rank parameterization rather than updating all pretrained weights.", tutorial="It motivates questions about whether learning factors, subspaces, or the fixed-rank object is the right geometric viewpoint.", reading="Hu et al. (2022); Li et al. (2025)", related=["Adapter", "Low-rank weight update", "Subspace learning"]),
    (term="Adapter", category="AI & Interpretability", definition="A small trainable module or parameter update inserted into or associated with a pretrained model for parameter-efficient adaptation.", tutorial="LoRA is a low-rank adapter strategy.", reading="Hu et al. (2022)", related=["LoRA", "Low-rank weight update"]),
    (term="Low-rank weight update", category="AI & Interpretability", definition="A weight change constrained to have low matrix rank.", tutorial="StelLA decomposes such an update as \$USV^\\top\$ to make input/output subspaces explicit.", reading="Li et al. (2025)", related=["LoRA", "Subspace learning", "Stiefel manifold"]),
    (term="Subspace learning", category="AI & Interpretability", definition="Learning the low-dimensional space in which useful updates or representations live, rather than assigning meaning to one particular basis.", tutorial="StelLA explicitly learns orthonormal input and output subspaces using Stiefel factors.", reading="Li et al. (2025)", related=["Subspace", "Stiefel manifold", "Orthonormal basis"]),
    (term="Factorized parameterization", category="AI & Interpretability", definition="Representing a low-rank object through factors, e.g. \$W=AB^\\top\$.", tutorial="It reduces parameter count but introduces non-unique coordinates and can affect conditioning.", reading="Bian et al. (2025)", related=["Parameter redundancy", "Fixed-rank weight", "Gauge freedom / equivalence"]),
    (term="Parameter redundancy", category="AI & Interpretability", definition="Different parameter values encode the same represented object or model behavior.", tutorial="RAdaGrad/RAdamW motivate direct fixed-rank optimization partly to avoid redundant factor coordinates.", reading="Bian et al. (2025)", related=["Factorized parameterization", "Coordinates vs represented object", "Fixed-rank manifold"]),
    (term="Fixed-rank weight", category="AI & Interpretability", definition="A matrix parameter constrained to have a specified rank.", tutorial="It can be optimized as an intrinsic matrix object rather than only through a factorization.", reading="Bian et al. (2025)", related=["Fixed-rank manifold", "Factorized parameterization", "Riemannian optimization"]),
    (term="RAdaGrad / RAdamW", category="AI & Interpretability", definition="Riemannian optimizers for fixed-rank matrix weights that adapt AdaGrad/AdamW-style metrics to the fixed-rank manifold.", tutorial="They illustrate geometry-aware low-rank learning without relying on a redundant factorization.", reading="Bian et al. (2025)", related=["Fixed-rank weight", "RGD", "Parameter redundancy"]),
    (term="Equivariance", category="AI & Interpretability", definition="A property where transforming the input induces a predictable corresponding transformation of the representation or output.", tutorial="Tensor Decomposition Networks study low-rank approximations inside SO(3)-equivariant architectures.", reading="Lin et al. (2025)", related=["Tensor product", "Clebsch–Gordan tensor product", "Low-rank tensor operator"]),
    (term="Tensor product", category="AI & Interpretability", definition="A multilinear construction that combines representation spaces or features.", tutorial="Equivariant networks may use structured tensor-product interactions that can be expensive.", reading="Lin et al. (2025)", related=["Equivariance", "Clebsch–Gordan tensor product"]),
    (term="Clebsch–Gordan tensor product", category="AI & Interpretability", definition="A structured tensor-product operation used to combine SO(3)-equivariant features while respecting representation-theoretic symmetry.", tutorial="TDNs replace expensive CG tensor-product operators with low-rank tensor decompositions.", reading="Lin et al. (2025)", related=["Equivariance", "Low-rank tensor operator", "Architectural compression"]),
    (term="Low-rank tensor operator", category="AI & Interpretability", definition="A tensor-valued or multilinear operator approximated using a low-rank tensor decomposition.", tutorial="TDNs use CP structure to reduce the cost of tensor-product operations.", reading="Lin et al. (2025)", related=["CP decomposition", "Architectural compression", "Separable interaction"]),
    (term="Architectural compression", category="AI & Interpretability", definition="Reducing computation or parameter cost by replacing a large operator or module with a structured lower-complexity approximation.", tutorial="In TDNs the low-rank tensor structure changes the architecture's operator implementation, not merely post-hoc interpretation.", reading="Lin et al. (2025)", related=["Low-rank tensor operator", "LoRA"]),
    (term="Separable interaction", category="AI & Interpretability", definition="An interaction that factors into products of simpler mode-wise terms.", tutorial="CP decomposition imposes a separability assumption on each rank-one component.", reading="Kolda & Bader (2009); Lin et al. (2025)", related=["CP decomposition", "Low-rank tensor operator"]),
    (term="Mechanistic interpretability", category="AI & Interpretability", definition="Studying internal model computations with the goal of identifying features, circuits, or mechanisms that explain behavior.", tutorial="SAE feature dictionaries are one current tool in this broader program.", reading="Cunningham et al. (2023); Bricken et al. (2023)", related=["Sparse autoencoder", "Activation patching", "Intervention"]),
    (term="Activation patching", category="AI & Interpretability", definition="Replacing or restoring internal activations from another run to test whether a particular activation state contributes causally to behavior.", tutorial="It is an intervention-style diagnostic distinct from merely observing a large feature activation.", reading="Mechanistic interpretability literature", related=["Intervention", "Ablation", "Causal relevance"]),
    (term="Ablation", category="AI & Interpretability", definition="Removing, zeroing, or disabling a feature, unit, component, or pathway and measuring the resulting behavioral change.", tutorial="It can provide causal evidence when appropriate controls rule out trivial distribution-shift effects.", reading="General interpretability literature", related=["Intervention", "Causal relevance", "Faithfulness"]),
    (term="Intervention", category="AI & Interpretability", definition="Deliberately changing a proposed mechanism or representation and testing whether the predicted effect follows.", tutorial="It is treated as stronger evidence than reconstruction or correlation alone.", reading="General causal and interpretability literature", related=["Ablation", "Activation patching", "Causal relevance"]),
    (term="Causal relevance", category="AI & Interpretability", definition="Evidence that changing a candidate feature or mechanism changes model behavior in the predicted way.", tutorial="A feature can be present or correlated without being causally important.", reading="Cunningham et al. (2023); general causal methodology", related=["Intervention", "Concept importance", "Feature activation"]),
    (term="Faithfulness", category="AI & Interpretability", definition="The degree to which an explanation accurately reflects the model computation or behavior it claims to explain.", tutorial="CRAFT evaluates concept-importance faithfulness; visual plausibility alone is not enough.", reading="Fel et al. (2023)", related=["Concept importance", "Semantic coherence", "Behavioral validation"]),
    (term="Semantic coherence", category="AI & Interpretability", definition="The extent to which examples strongly associated with a learned feature support a consistent human interpretation.", tutorial="Coherence supports naming a candidate concept but does not alone establish causal importance.", reading="Ghorbani et al. (2019); Fel et al. (2023)", related=["Concept discovery", "Monosemanticity", "Semantic validation"]),
    (term="Stability", category="AI & Interpretability", definition="Persistence of a candidate structure across reasonable changes in initialization, samples, ranks, perturbations, or solver choices.", tutorial="Stable recovery is a prerequisite for strong component-level interpretation.", reading="Labs 3–4", related=["Identifiability", "Held-out validation", "Feature universality"]),
    (term="Feature universality", category="AI & Interpretability", definition="The hypothesis or observation that similar learned features recur across models, scales, seeds, or training settings.", tutorial="It can strengthen evidence that a feature is not a one-run artifact, but matching features across representations requires care.", reading="SAE / representation comparison literature", related=["Stability", "Semantic coherence"]),
    (term="Held-out validation", category="AI & Interpretability", definition="Testing a claim on data that were not used to fit or select the representation.", tutorial="A semantic label should generalize beyond the examples used to invent that label.", reading="Standard machine-learning methodology", related=["Behavioral validation", "Semantic validation", "Stability"]),
    (term="Behavioral validation", category="AI & Interpretability", definition="Testing whether a proposed concept is meaningfully related to model outputs on external examples or tasks.", tutorial="It separates 'this factor looks interpretable' from 'this factor predicts something about model behavior'.", reading="Kim et al. (2018); Ghorbani et al. (2019); Fel et al. (2023)", related=["Held-out validation", "Concept importance", "Faithfulness"]),
    (term="Semantic validation", category="AI & Interpretability", definition="Evidence that a mathematical factor corresponds to the domain meaning assigned to it.", tutorial="High-usage examples can suggest a label; stability, held-out behavior, or interventions strengthen the claim.", reading="Tutorial synthesis", related=["Concept", "Dictionary atom", "Behavioral validation"]),
    (term="Reconstruction", category="AI & Interpretability", definition="How accurately a learned representation reproduces the data or activation object it was fit to.", tutorial="Good reconstruction is necessary for representation fidelity but does not validate semantics, uniqueness, or causal importance.", reading="Labs 2–4", related=["Relative reconstruction error", "Semantic validation", "Faithfulness"]),
    (term="Alignment-relevant evidence", category="AI & Interpretability", definition="Representation- or behavior-level evidence that may support auditing or monitoring questions relevant to system behavior.", tutorial="The tutorial does not present tensor decomposition as an alignment algorithm; it studies when low-rank evidence is sufficiently invariant, stable, and behaviorally validated to be useful for auditing.", reading="Tutorial synthesis", related=["Behavioral validation", "Intervention", "Stability"])
]

const RAW_REFERENCES = [(key="Kolda & Bader (2009)", citation="T. G. Kolda and B. W. Bader. Tensor Decompositions and Applications. SIAM Review 51(3):455–500, 2009. DOI 10.1137/07070111X."),
    (key="De Lathauwer et al. (2000)", citation="L. De Lathauwer, B. De Moor, and J. Vandewalle. A Multilinear Singular Value Decomposition. SIAM Journal on Matrix Analysis and Applications 21(4):1253–1278, 2000."),
    (key="De Lathauwer (2008)", citation="L. De Lathauwer. Decompositions of a Higher-Order Tensor in Block Terms—Part II: Definitions and Uniqueness. SIAM Journal on Matrix Analysis and Applications 30(3):1033–1066, 2008. DOI 10.1137/070690729."),
    (key="Absil et al. (2008)", citation="P.-A. Absil, R. Mahony, and R. Sepulchre. Optimization Algorithms on Matrix Manifolds. Princeton University Press, 2008."),
    (key="Breiding & Vannieuwenhoven (2018)", citation="P. Breiding and N. Vannieuwenhoven. A Riemannian Trust Region Method for the Canonical Tensor Rank Approximation Problem. SIAM Journal on Optimization 28(3):2435–2465, 2018. DOI 10.1137/17M114618X."),
    (key="Lee & Seung (1999)", citation="D. D. Lee and H. S. Seung. Learning the Parts of Objects by Non-negative Matrix Factorization. Nature 401:788–791, 1999. DOI 10.1038/44565."),
    (key="Mairal et al. (2009)", citation="J. Mairal, F. Bach, J. Ponce, and G. Sapiro. Online Dictionary Learning for Sparse Coding. ICML 2009, pp. 689–696. DOI 10.1145/1553374.1553463."),
    (key="Goodfellow et al. (2016)", citation="I. Goodfellow, Y. Bengio, and A. Courville. Deep Learning. MIT Press, 2016."),
    (key="Kim et al. (2018)", citation="B. Kim et al. Interpretability Beyond Feature Attribution: Quantitative Testing with Concept Activation Vectors (TCAV). ICML 2018, PMLR 80:2668–2677."),
    (key="Ghorbani et al. (2019)", citation="A. Ghorbani, J. Wexler, J. Y. Zou, and B. Kim. Towards Automatic Concept-based Explanations. NeurIPS 2019, pp. 9277–9286."),
    (key="Fel et al. (2023)", citation="T. Fel et al. CRAFT: Concept Recursive Activation FacTorization for Explainability. CVPR 2023, pp. 2711–2721."),
    (key="Hu et al. (2022)", citation="E. J. Hu et al. LoRA: Low-Rank Adaptation of Large Language Models. ICLR 2022."),
    (key="Cunningham et al. (2023)", citation="H. Cunningham, A. Ewart, L. Riggs, R. Huben, and L. Sharkey. Sparse Autoencoders Find Highly Interpretable Features in Language Models. arXiv:2309.08600, 2023."),
    (key="Bricken et al. (2023)", citation="T. Bricken et al. Towards Monosemanticity: Decomposing Language Models With Dictionary Learning. Anthropic research report, 2023."),
    (key="Templeton et al. (2026)", citation="A. Templeton et al. Scaling Monosemanticity: Extracting Interpretable Features from Claude 3 Sonnet. arXiv:2605.29358, 2026."),
    (key="Li et al. (2025)", citation="Z. Li, S. Sajadmanesh, J. Li, and L. Lyu. StelLA: Subspace Learning in Low-rank Adaptation using Stiefel Manifold. NeurIPS 38, 2025."),
    (key="Bian et al. (2025)", citation="F. Bian, J. Zheng, Z. Liu, J. Luo, and J.-F. Cai. Finding Low-Rank Matrix Weights in DNNs via Riemannian Optimization: RAdaGrad and RAdamW. NeurIPS 38, 2025."),
    (key="Lin et al. (2025)", citation="Y. Lin et al. Tensor Decomposition Networks for Fast Machine Learning Interatomic Potential Computations. NeurIPS 38, 2025.")]


const MATH_CLUSTER_TERMS = [
    "I. Tensor basics" => Set([
        "Tensor", "Mode", "Matricization / unfolding", "Outer product",
        "Rank-one tensor", "Matrix rank",
    ]),
    "II. Decomposition models" => Set([
        "CP decomposition", "CP rank", "Factor matrix", "Tucker decomposition",
        "Core tensor", "Multilinear rank", "HOSVD",
        "Block-Term Decomposition / BTD", "SVD",
    ]),
    "III. Geometry and equivalence" => Set([
        "Subspace", "Orthonormal basis", "Manifold", "Stiefel manifold",
        "Segre manifold / variety", "Fixed-rank manifold",
        "Coordinates vs represented object", "Gauge freedom / equivalence",
        "Scaling ambiguity", "Permutation ambiguity", "Identifiability",
    ]),
    "IV. Optimization" => Set([
        "Nonconvex optimization", "Initialization", "ALS", "RALS",
        "Regularized ALS",
        "Riemannian optimization", "Tangent space", "Retraction", "RGD", "RCG",
        "Levenberg–Marquardt / LM",
    ]),
    "V. Failure and stability" => Set([
        "Conditioning", "Condition number", "Relative reconstruction error",
        "Overparameterization / excessive rank", "Rank choice",
        "Component collision", "Degeneracy", "Cancellation",
        "Swamp / swamp-like stagnation", "Model mismatch",
    ]),
]

const AI_CLUSTER_TERMS = [
    "I. Neural representations" => Set([
        "Neural representation", "Activation", "Activation space",
        "Latent representation", "Representation learning", "Feature",
        "Feature direction",
    ]),
    "II. Dictionary representations" => Set([
        "Dictionary learning", "Dictionary atom", "Sparse coding", "Sparsity",
        "Sparsity penalty", "Autoencoder", "Encoder", "Decoder", "Latent code",
        "Sparse autoencoder / SAE", "Overcomplete dictionary",
        "Feature activation", "Dead feature / dead latent", "Monosemanticity",
        "Polysemanticity", "Superposition", "Feature splitting", "NMF",
    ]),
    "III. Concept-based interpretability" => Set([
        "Concept", "Concept-based interpretability", "Concept discovery",
        "Feature attribution", "Concept attribution", "CAV", "TCAV", "ACE",
        "CRAFT", "Image crop / patch", "Global average pooling", "Concept bank",
        "Concept usage / coefficient", "Concept importance", "Sobol sensitivity",
        "Concept Attribution Map", "Recursive concept decomposition",
        "Concept granularity",
    ]),
    "IV. Low-rank learning in neural networks" => Set([
        "LoRA", "Adapter", "Low-rank weight update", "Subspace learning",
        "Factorized parameterization", "Parameter redundancy",
        "Fixed-rank weight", "RAdaGrad / RAdamW", "Equivariance",
        "Tensor product", "Clebsch–Gordan tensor product",
        "Low-rank tensor operator", "Architectural compression",
        "Separable interaction",
    ]),
    "V. Evidence and validation" => Set([
        "Mechanistic interpretability", "Activation patching", "Ablation",
        "Intervention", "Causal relevance", "Faithfulness",
        "Semantic coherence", "Stability", "Feature universality",
        "Held-out validation", "Behavioral validation", "Semantic validation",
        "Reconstruction", "Alignment-relevant evidence",
    ]),
]

const CLUSTER_ORDER = Dict(
    "Mathematics" => first.(MATH_CLUSTER_TERMS),
    "AI & Interpretability" => first.(AI_CLUSTER_TERMS),
)

const NOTE_CONFIG = Dict(
    "Gauge freedom / equivalence" => (
        label = "Why it matters",
        note = "A change in factors does not necessarily mean a change in the represented object.",
    ),
    "Identifiability" => (
        label = "Interpretation boundary",
        note = "Identifiability supports coordinate recovery, but an identifiable factor is not automatically a scientifically meaningful concept.",
    ),
    "Conditioning" => (
        label = "Interpretation boundary",
        note = "A low reconstruction error can coexist with component coordinates that are too sensitive for reliable interpretation.",
    ),
    "Rank choice" => (
        label = "Interpretation boundary",
        note = "More rank can split or duplicate a vocabulary rather than merely improve the fit.",
    ),
    "Component collision" => (
        label = "Why it matters",
        note = "Nearly indistinguishable rank-one terms can make component roles difficult to separate and local optimization problems poorly conditioned.",
    ),
    "Dictionary atom" => (
        label = "Interpretation boundary",
        note = "A reusable learned direction is not automatically a human-meaningful concept.",
    ),
    "Sparse autoencoder / SAE" => (
        label = "Interpretation boundary",
        note = "An SAE feature is a learned representation direction, not automatically a validated semantic concept.",
    ),
    "NMF" => (
        label = "Interpretation boundary",
        note = "Nonnegativity encourages additive coordinates; it does not guarantee uniqueness or semantic meaning.",
    ),
    "CAV" => (
        label = "Interpretation boundary",
        note = "A direction in activation space becomes a defensible concept only after semantic and behavioral validation.",
    ),
    "Concept bank" => (
        label = "Interpretation boundary",
        note = "A collection of candidate directions is a learned representation, not yet a validated concept vocabulary.",
    ),
    "Concept importance" => (
        label = "Why it matters",
        note = "A concept can be strongly present in an activation while having little effect on the model's output.",
    ),
    "Stability" => (
        label = "Interpretation boundary",
        note = "A candidate that does not persist across reasonable runs, ranks, samples, or perturbations is weak evidence for component-level interpretation.",
    ),
    "Reconstruction" => (
        label = "Interpretation boundary",
        note = "Good reconstruction does not establish uniqueness, stability, semantic meaning, or causal relevance.",
    ),
)

const REFERENCE_KEYS = Dict(
    "Kolda & Bader (2009)" => "KB09",
    "De Lathauwer et al. (2000)" => "DLV00",
    "De Lathauwer (2008)" => "DL08",
    "Absil et al. (2008)" => "AMS08",
    "Breiding & Vannieuwenhoven (2018)" => "BV18",
    "Lee & Seung (1999)" => "LS99",
    "Mairal et al. (2009)" => "MBPS09",
    "Goodfellow et al. (2016)" => "GBC16",
    "Kim et al. (2018)" => "KIM18",
    "Ghorbani et al. (2019)" => "GHO19",
    "Fel et al. (2023)" => "FEL23",
    "Hu et al. (2022)" => "HUE22",
    "Cunningham et al. (2023)" => "CUN23",
    "Bricken et al. (2023)" => "BRI23",
    "Templeton et al. (2026)" => "TEM26",
    "Li et al. (2025)" => "LIS25",
    "Bian et al. (2025)" => "BIA25",
    "Lin et al. (2025)" => "LIN25",
)

const REFERENCE_ALIASES = [
    "Kolda & Bader (2009)" => "KB09",
    "De Lathauwer, De Moor & Vandewalle (2000)" => "DLV00",
    "De Lathauwer et al. (2000)" => "DLV00",
    "De Lathauwer (2008)" => "DL08",
    "Absil, Mahony & Sepulchre (2008)" => "AMS08",
    "Absil et al. (2008)" => "AMS08",
    "Breiding & Vannieuwenhoven (2018)" => "BV18",
    "Lee & Seung (1999)" => "LS99",
    "Mairal et al. (2009)" => "MBPS09",
    "Goodfellow et al. (2016)" => "GBC16",
    "Kim et al. (2018)" => "KIM18",
    "Ghorbani et al. (2019)" => "GHO19",
    "Fel et al. (2023)" => "FEL23",
    "Hu et al. (2022)" => "HUE22",
    "Cunningham et al. (2023)" => "CUN23",
    "Bricken et al. (2023)" => "BRI23",
    "Templeton et al. (2026)" => "TEM26",
    "Li et al. (2025)" => "LIS25",
    "Bian et al. (2025)" => "BIA25",
    "Lin et al. (2025)" => "LIN25",
]

const GLOSSARY_REFERENCES = [
    (
        short = REFERENCE_KEYS[reference.key],
        key = reference.key,
        citation = reference.citation,
    )
    for reference in RAW_REFERENCES
]

function glossary_cluster(term, category)
    clusters = category == "Mathematics" ? MATH_CLUSTER_TERMS : AI_CLUSTER_TERMS
    for (cluster, terms) in clusters
        term in terms && return cluster
    end
    error("No glossary cluster assigned to $(repr(term))")
end

function citation_keys(reading)
    keys = String[]
    for (pattern, key) in REFERENCE_ALIASES
        occursin(pattern, reading) && key ∉ keys && push!(keys, key)
    end
    keys
end

function normalize_entry(raw)
    note_config = get(NOTE_CONFIG, raw.term, nothing)
    summary = isnothing(note_config) ?
        string(raw.definition, " ", raw.tutorial) :
        raw.definition
    (
        term = raw.term,
        category = raw.category,
        cluster = glossary_cluster(raw.term, raw.category),
        summary = summary,
        note_label = isnothing(note_config) ? nothing : note_config.label,
        note = isnothing(note_config) ? nothing : note_config.note,
        citations = citation_keys(raw.reading),
    )
end

const GLOSSARY_ENTRIES = normalize_entry.(vcat(RAW_MATH_GLOSSARY, RAW_AI_GLOSSARY))

end
