package assimp

import c "core:c/libc"
import   "core:os"

when os.OS == .Windows {
	foreign import assimp "./assimp.lib"
} else {
	foreign import assimp "system:assimp"
}

@(default_calling_convention="c", link_prefix="ai")
foreign assimp {
	ImportFile                 :: proc(path: cstring, flags: c.uint) -> ^Scene ---
	ReleaseImport              :: proc(scene: ^Scene) ---
	GetErrorString             :: proc() -> cstring ---
	IdentityMatrix4            :: proc(dest: ^Mat4) ---
	MultiplyMatrix4            :: proc(dest: ^Mat4, src: ^Mat4) ---
	TransformVecByMatrix4      :: proc(vec: ^Vector3D, mat: ^Mat4) ---
	TransformVecByMatrix3      :: proc(vec: ^Vector3D, mat: ^Mat3) ---
	Matrix3FromMatrix4         :: proc(dest: ^Mat3, src: ^Mat4) ---

	GetMaterialFloatArray :: proc(
		material: ^Material,
		key:       cstring,
		type:      TextureType,
		index:     c.uint,
		out:      ^f32,
		max:      ^c.uint,
	) ---

	GetMaterialColor :: proc(
		material: ^Material,
		key:       cstring,
		type:      TextureType,
		index:     c.uint,
		out:      ^Color4D,
	) ---

	GetMaterialTextureCount :: proc(material: ^Material, type: TextureType) -> c.uint ---

	GetMaterialTexture :: proc(
		material: ^Material,
		type: TextureType,
		index: c.uint,
		path: ^String,
		mapping: ^TextureMapping = nil,
		uv_index: ^c.uint = nil,
		blend: ^f32 = nil,
		op: ^TextureOp = nil,
		mapmode: ^TextureMapMode = nil,
		flags: ^c.uint = nil,
	) ---
}

PostProcessFlags :: enum(c.uint) {
	CalcTangentSpace         = 0x00000001,
	JoinIdenticalVertices    = 0x00000002,
	MakeLeftHanded           = 0x00000004,
	Triangulate              = 0x00000008,
	RemoveComponent          = 0x00000010,
	GenNormals               = 0x00000020,
	GenSmoothNormals         = 0x00000040,
	SplitLargeMeshes         = 0x00000080,
	PreTransformVertices     = 0x00000100,
	LimitBoneWeights         = 0x00000200,
	ValidateDataStructure    = 0x00000400,
	ImproveCacheLocality     = 0x00000800,
	RemoveRedundantMaterials = 0x00001000,
	FixInfacingNormals       = 0x00002000,
	PoplateArmatureData      = 0x00004000,
	SortByPType              = 0x00008000,
	FindDegenerates          = 0x00010000,
	FindInvalidData          = 0x00020000,
	GenUVCoords              = 0x00040000,
	TransformUVCoords        = 0x00080000,
	FindInstances            = 0x00100000,
	OptimizeMeshes           = 0x00200000,
	OptimizeGraph            = 0x00400000,
	FlipUVs                  = 0x00800000,
	FlipWindingOrder         = 0x01000000,
	SplitByBoneCount         = 0x02000000,
	Debone                   = 0x04000000,
	GlobalScale              = 0x08000000,
	EmbedTextures            = 0x10000000,
	ForceGenNormals          = 0x20000000,
	DropNormals              = 0x40000000,
	GenBoundingBoxes         = 0x80000000,
}

SceneFlags :: enum(c.uint) {
	Incomplete        = 0x01,
	Validated         = 0x02,
	ValidationWarning = 0x04,
	NonVerboseFormat  = 0x08,
	FlagsTerrain      = 0x10,
	AllowShared       = 0x20,
}

Scene :: struct {
	flags:              c.uint,
	root_node:         ^Node,
	num_meshes:         c.uint,
	meshes:         [^]^Mesh,
	num_materials:      c.uint,
	materials:      [^]^Material,
	num_animations:     c.uint,
	animations:     [^]^Animation,
	num_textures:       c.uint,
	textures:       [^]^Texture,
	num_lights:         c.uint,
	lights:         [^]^Light,
	num_cameras:        c.uint,
	cameras:        [^]^Camera,
	metadata:          ^Metadata,
	name:               String,
	skeletons:      [^]^Skeleton,
	private_data_do_not_touch: rawptr,
}

Node :: struct {
	name:             String,
	transform:        Mat4,
	parent:          ^Node,
	num_children:     c.uint,
	children:     [^]^Node,
	num_meshes:       c.uint,
	meshes:        [^]c.uint,
	metadata:        ^Metadata,
}

PrimitiveType :: enum(c.uint) {
	Point            = 0x01,
	Line             = 0x02,
	Triangle         = 0x04,
	Polygon          = 0x08,
	NGonEncodingFlag = 0x10,
}

MAX_NUMBER_OF_COLOR_SETS    :: 0x8
MAX_NUMBER_OF_TEXTURECOORDS :: 0x8

MAX_FACE_INDICES :: 0x7fff
MAX_BONE_WEIGHTS :: 0x7fffffff
MAX_VERTICES     :: 0x7fffffff
MAX_FACES        :: 0x7fffffff

MorphingMethod :: enum(c.uint) {
	VertexBlend     = 0x1,
	MorphNormalized = 0x2,
	MorphRelative   = 0x3,
}

Mesh :: struct {
	primitive_types:       c.uint,
	num_vertices:          c.uint,
	num_faces:             c.uint,
	vertices:           [^]Vector3D,
	normals:            [^]Vector3D,
	tangents:           [^]Vector3D,
	bitangents:         [^]Vector3D,
	colors:               [MAX_NUMBER_OF_COLOR_SETS]^Color4D,
	texture_coords:       [MAX_NUMBER_OF_TEXTURECOORDS][^]Vector3D,
	num_uv_components:    [MAX_NUMBER_OF_TEXTURECOORDS]c.uint,
	faces:              [^]Face,
	num_bones:             c.uint,
	bones:             [^]^Bone,
	material_index:        c.uint,
	name:                  String,
	num_anim_meshes:       c.uint,
	anim_meshes:       [^]^AnimMesh,
	method:                MorphingMethod,
	aabb:                  AABB,
	texture_coords_names: [^]^String,
}

AnimMesh :: struct {
	name:              String,
	vertices:       [^]Vector3D,
	normals:        [^]Vector3D,
	tangents:       [^]Vector3D,
	bitangents:     [^]Vector3D,
	colors:           [MAX_NUMBER_OF_COLOR_SETS]^Color4D,
	texture_coords:   [MAX_NUMBER_OF_TEXTURECOORDS]^Vector3D,
	num_vertices:      c.uint,
	weight:            c.float,
}

Face :: struct {
	num_indices:    c.uint,
	indices:     [^]c.uint,
}

Bone :: struct {
	name:           String,
	num_weights:    c.uint,
	weights:     [^]VertexWeight,
	offset_mat:     Mat4,
}

VertexWeight :: struct {
	vertex_id: c.uint,
	weight:    c.float,
}

SkeletonBone :: struct {
	parent:         c.int,
	num_weights:    c.uint,
	mesh_id:       ^Mesh,
	weights:     [^]VertexWeight,
	offset_mat:     Mat4,
	local_mat:      Mat4,
}

Skeleton :: struct {
	name:          String,
	num_bones:     c.uint,
	bones:     [^]^SkeletonBone,
}

TextureOp :: enum(c.uint) {
	Multiply  = 0x0,
	Add       = 0x1,
	Subtract  = 0x2,
	Divide    = 0x3,
	SmoothAdd = 0x4,
	SignedAdd = 0x5,
}

TextureMapMode :: enum(c.uint) {
	Wrap   = 0x0,
	Clamp  = 0x1,
	Decal  = 0x3,
	Mirrow = 0x2,
}

TextureMapping :: enum(c.uint) {
	UV       = 0x0,
	Sphere   = 0x1,
	Cylinder = 0x2,
	Box      = 0x3,
	Plane    = 0x4,
	Other    = 0x5,
}

TEXTURE_TYPE_MAX :: TextureType.Transmission

TextureType :: enum(c.uint) {
	None             = 0,
	Diffuse          = 1,
	Specular         = 2,
	Ambient          = 3,
	Emissive         = 4,
	Height           = 5,
	Normals          = 6,
	Shininess        = 7,
	Opacity          = 8,
	Displacement     = 9,
	Lightmap         = 10,
	Reflection       = 11,
	BaseColor        = 12,
	NormalCamera     = 13,
	EmissionColor    = 14,
	Metalness        = 15,
	DiffuseRoughness = 16,
	AmbientOcclusion = 17,
	Sheen            = 19,
	Clearcoat        = 20,
	Transmission     = 21,
	Unknown          = 18,
}

ShadingMode :: enum(c.uint) {
	Flat         = 0x1,
	Gouraud      = 0x2,
	Phong        = 0x3,
	Blinn        = 0x4,
	Toon         = 0x5,
	OrenNayar    = 0x6,
	Minnaert     = 0x7,
	CookTorrance = 0x8,
	NoShading    = 0x9,
	Unlit        = 0x9,
	Fresnel      = 0xa,
	PbrBrdf      = 0xb,
}

TextureFlags :: enum(c.uint) {
	Invert      = 0x1,
	UseAlpha    = 0x2,
	IgnoreAlpha = 0x4,
}

BlendMode :: enum(c.uint) {
	Default  = 0x0,
	Additive = 0x1,
}

UVTransform :: struct {
	translation: Vector2D,
	scaling:     Vector2D,
	rotation:    c.float,
}

PropertyTypeInfo :: enum(c.uint) {
	Float   = 0x1,
	Double  = 0x2,
	String  = 0x3,
	Integer = 0x4,
	Buffer  = 0x5,
}

MATKEY_SHININESS_KEY :: "$mat.shininess"
MATKEY_SHININESS_TY  :: TextureType.None
MATKEY_SHININESS_IDX :: 0

MATKEY_ROUGHNESS_FACTOR_KEY :: "$mat.roughnessFactor"
MATKEY_ROUGHNESS_FACTOR_TY  :: TextureType.None
MATKEY_ROUGHNESS_FACTOR_IDX :: 0

MATKEY_COLOR_DIFFUSE_KEY :: "$clr.diffuse"
MATKEY_COLOR_DIFFUSE_TY  :: TextureType.None
MATKEY_COLOR_DIFFUSE_IDX :: 0

MATKEY_COLOR_BASE_KEY :: "$clr.base"
MATKEY_COLOR_BASE_TY  :: TextureType.None
MATKEY_COLOR_BASE_IDX :: 0

MaterialProperty :: struct {
	key:            String,
	semantic:       c.uint,
	index:          c.uint,
	data_length:    c.uint,
	type:           PropertyTypeInfo,
	data:        [^]c.uchar,
}

Material :: struct {
	properties:     [^]^MaterialProperty,
	num_properties:     c.uint,
	num_allocated:      c.uint,
}

Animation :: struct {
	name:                        String,
	duration:                    c.double,
	ticks_per_sec:               c.double,
	num_channels:                c.uint,
	channels:                [^]^NodeAnim,
	num_mesh_channels:           c.uint,
	mesh_channels:           [^]^MeshAnim,
	num_morph_mesh_channels:     c.uint,
	morph_mesh_channels:     [^]^MeshMorphAnim,
}

AnimBehavior :: enum(c.uint) {
	Default  = 0x0,
	Constant = 0x1,
	Linear   = 0x2,
	Repeat   = 0x3,
}

MeshMorphKey :: struct {
	time:                      c.double,
	values:                 [^]c.uint,
	weights:                [^]c.double,
	num_values_and_weights:    c.uint,
}

MeshKey :: struct {
	time:  c.double,
	value: c.uint,
}

VectorKey :: struct {
	time:  c.double,
	value: Vector3D,
}

QuatKey :: struct {
	time:  c.double,
	value: Quat,
}

NodeAnim :: struct {
	name:                 String,
	num_position_keys:    c.uint,
	position_keys:     [^]VectorKey,
	num_rotation_keys:    c.uint,
	rotation_keys:     [^]QuatKey,
	num_scaling_keys:     c.uint,
	scaling_keys:      [^]VectorKey,
	pre_state:            AnimBehavior,
	post_state:           AnimBehavior,
}

MeshAnim :: struct {
	name:        String,
	num_keys:    c.uint,
	keys:     [^]MeshKey,
}

MeshMorphAnim :: struct {
	name:     String,
	num_keys: c.uint,
	keys:     MeshMorphKey,
}

HINT_MAX_TEXTURE_LEN :: 9

Texture :: struct {
	width:          c.uint,
	height:         c.uint,
	format_hint:   [HINT_MAX_TEXTURE_LEN]c.char,
	data:        [^]Texel,
	filename:       String,
}

Texel :: struct {
	b, g, r, a: c.uchar,
}

LightSourceType :: enum(c.uint) {
	Undefined   = 0x0,
	Directional = 0x1,
	Point       = 0x2,
	Spot        = 0x3,
	Ambient     = 0x4,
	Area        = 0x5,
}

Light :: struct {
	name:                  String,
	type:                  LightSourceType,
	position:              Vector3D,
	direction:             Vector3D,
	up:                    Vector3D,
	attenuation_constant:  c.float,
	attenuation_linear:    c.float,
	attenuation_quadratic: c.float,
	color_diffuse:         Color3D,
	color_specular:        Color3D,
	color_ambient:         Color3D,
	angle_inner_cone:      c.float,
	angle_outer_cone:      c.float,
	size:                  Vector2D,
}

Camera :: struct {
	name:            String,
	position:        Vector3D,
	up:              Vector3D,
	look_at:         Vector3D,
	h_fov:           c.float,
	clip_plane_near: c.float,
	clip_plane_far:  c.float,
	aspect_ratio:    c.float,
	ortho_width:     c.float,
}

MetadataType :: enum(c.uint) {
	Bool       = 0,
	Int32      = 1,
	UInt32     = 2,
	Float      = 3,
	Double     = 4,
	AIString   = 5,
	AIVector3D = 6,
	AIMetadata = 7,
	MetaMax    = 8,
}

Metadata :: struct {
	num_properties:    c.uint,
	keys:           [^]String,
	values:         [^]MetadataEntry,
}

MetadataEntry :: struct {
	type: MetadataType,
	data: rawptr,
}

MAX_STRING_LEN :: 1024

String :: struct {
	length: u32,
	data: [MAX_STRING_LEN]c.char,
}

Vector2D :: struct {
	x, y: c.float,
}

Vector3D :: struct {
	x, y, z: c.float,
}

Quat :: struct {
	w, x, y, z: c.float,
}

Mat3 :: struct {
	a1, a2, a3: c.float,
	b1, b2, b3: c.float,
	c1, c2, c3: c.float,
}

Mat4 :: struct {
	a1, a2, a3, a4: c.float,
	b1, b2, b3, b4: c.float,
	c1, c2, c3, c4: c.float,
	d1, d2, d3, d4: c.float,
}

AABB :: struct {
	min, max: Vector3D,
}

Color3D :: struct {
	r, g, b: c.float,
}

Color4D :: struct {
	r, g, b, a: c.float,
}
