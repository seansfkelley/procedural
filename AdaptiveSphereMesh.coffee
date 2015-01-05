tileSquare = (corner1, corner2, normal, segments) ->
  geometry = new THREE.Geometry

  diagonalLength = corner2.distanceTo corner1
  diagonal1 = new THREE.Vector3().subVectors(corner2, corner1).setLength(diagonalLength / 2)
  diagonal2 = new THREE.Vector3().crossVectors(normal, diagonal1).setLength(diagonalLength / 2)

  a = corner1
  b = corner1.clone().add(diagonal1).add(diagonal2)
  c = corner2

  vertical   = new THREE.Vector3().subVectors(b, a).divideScalar(segments)
  horizontal = new THREE.Vector3().subVectors(c, b).divideScalar(segments)

  i = 0
  start = corner1.clone()
  for x in [0...segments]
    iterator = start.clone()
    start.add horizontal
    for y in [0...segments]
      geometry.vertices.push(
        iterator.clone()
        iterator.clone().add(vertical)
        iterator.clone().add(horizontal)
        iterator.clone().add(horizontal).add(vertical)
      )
      geometry.faces.push(
        new THREE.Face3(i, i + 1, i + 2, normal.clone())
        new THREE.Face3(i + 2, i + 1, i + 3, normal.clone()) # Ordering: maintain CW.
      )
      i += 4
      iterator.add vertical

  geometry.mergeVertices()
  return geometry

sign = (n) -> `n < 0 ? -1 : (n > 0 ? 1 : 0)`

class window.QuadtreeMesh extends THREE.Object3D
  constructor : (geometry, axis, material = null) ->
    # Discovered this myself. Others have the same issue:
    # http://blog.olav.it/post/44702519698/subclassing-three-js-objects-in-coffeescript
    THREE.Object3D.call this

    @_buildQuadtree geometry.vertices, axis, material
    @add @_quadtree

  _buildQuadtree : (vertices, axis, material) ->
    axesToKeep = _.without [ 'x', 'y', 'z' ], axis

    # These Vector2s are a "projection" into 2D space, but mostly logically speaking --
    # it's possible that the z coordinate gets mapped onto one named x or y, but we only
    # need this abstraction for assigning groups. I don't think it can be used for
    # physical positioning at all.
    vertices2d = vertices.map (v) -> new THREE.Vector2 v[axesToKeep[0]], v[axesToKeep[1]]

    @_quadtree = new QuadtreeMeshNode vertices, vertices2d, material

  refocus : (nearestPoint2d) ->
    @_quadtree.refocus nearestPoint2d

[ QUADRANT_NE, QUADRANT_NW, QUADRANT_SW, QUADRANT_SE ] = [0...4]

class QuadtreeMeshNode extends THREE.Object3D
  constructor : (vertices, vertices2d, material = null, depth = 0) ->
    THREE.Object3D.call this

    if vertices.length < 20
      # Add to geometry, unless I can just replace it?
      _nodeVertices = vertices
    else
      # Add to geometry.
      _nodeVertices = @_simplifyVerticesToDepth vertices, depth
      @_quadtreeChildren = @_computeQuadtreeChildren vertices, vertices2d, material, depth

    @_nodeMesh = new THREE.Mesh(
      # TODO: How do we save the geometry that corresponds to these vertices? Currently there
      # is nothing to actually render. :( Must use _nodeGeometry.
      new THREE.Geometry
      material
    )

    @add @_nodeMesh

  # Need better name.
  refocus : (nearestPoint2d) ->
    if @_quadtreeChildren?
      @remove @_nodeMesh
      if @_nearEnoughToRecurse()
        # Figure out where to recurse, add the other three meshes and refocus the last one.
      else
        @add @_nodeMesh
    # Else, nothing to do: we're a leaf.

  _nearEnoughToRecurse : -> false

  _computeQuadtreeChildren : (vertices, vertices2d, material, depth) ->
    center = @_getCenter vertices2d
    corners = [0...4].map -> { vertices : [], vertices2d : [] }

    for v, i in vertices2d
      cornerIndex = switch
        when v.x >  center.x and v.y >  center.y then QUADRANT_NE
        when v.x >  center.x and v.y <= center.y then QUADRANT_NW
        when v.x <= center.x and v.y <= center.y then QUADRANT_SW
        else QUADRANT_SE
      corners[cornerIndex].vertices.push vertices[i]
      corners[cornerIndex].vertices2d.push v

    return corners.map ({ vertices, vertices2d }) -> new QuadtreeMeshNode vertices, vertices2d, material, depth + 1

  _getCenter : (vertices2d) ->
    lowCorner  = new THREE.Vector2  Infinity,  Infinity
    highCorner = new THREE.Vector2 -Infinity, -Infinity

    for v in vertices2d
      lowCorner.min  v
      highCorner.max v

    return new THREE.Vector2().addVectors(lowCorner, highCorner).divideScalar 2

  _simplifyVerticesToDepth : (vertices, depth) ->
    return []

class window.AdaptiveSphereMesh extends THREE.Object3D
  @SPHERE_RADIUS : 25

  constructor : (material = null) ->
    THREE.Object3D.call this

    # +z is into the screen, but only for cube mapping. Normally it's out of the screen.
    # OpenGL directionality here such that when mapped onto the standard flat texture origin is always bottom-left:
    #       ____                      _____
    #      |    |                    |    ↗|
    #      | +y |                    |  ↗  |
    #  ____|____|____ ____      _____|↗____|_____ _____
    # |    |    |    |    |    |    ↗|    ↗|    ↗|    ↗|
    # | -x | +z | +x | -z |    |  ↗  |  ↗  |  ↗  |  ↗  |
    # |____|____|____|____|    |↗____|↗____|↗____|↗____|
    #      |    |                    |    ↗|
    #      | -y |                    |  ↗  |
    #      |____|                    |↗____|
    #
    @_sphereFaceMeshes = [
      origin    : new THREE.Vector3( 1, -1,  1)
      face      : 'x'
      direction : 1
    ,
      origin    : new THREE.Vector3(-1, -1,  1)
      face      : 'x'
      direction : -1
    ,
      origin    : new THREE.Vector3(-1,  1,  1)
      face      : 'y'
      direction : 1
    ,
      origin    : new THREE.Vector3(-1, -1, -1)
      face      : 'y'
      direction : -1
    ,
      origin    : new THREE.Vector3(-1, -1,  1)
      face      : 'z'
      direction : 1
    ,
      origin    : new THREE.Vector3( 1, -1, -1)
      face      : 'z'
      direction : -1
    ].map ({ origin, face, direction }) =>
      normal = new THREE.Vector3
      normal[face] = direction
      target = origin.clone().negate().multiplyScalar(2).add(origin)
      target[face] = direction
      g = tileSquare(origin, target, normal, 50)
      for v in g.vertices
        v.setLength @constructor.SPHERE_RADIUS
      return new QuadtreeMesh g, face, material

    for m in @_sphereFaceMeshes
      console.log m
      @add m

    return # loop

  _getFace : (v) ->
    [ x, y, z ] = v.toArray().map Math.abs
    if x >= y and x >= z
      return 'x'
    else if y >= x and y >= z
      return 'y'
    else if z >= x and z >= y
      return 'z'
    throw new Error 'math is hard'

  projectOntoSphere : (v) ->
    return v.clone().sub(@position).setLength(@constructor.SPHERE_RADIUS)

  projectOntoCube : (v) ->
    return @projectOntoSphere(v).multiplyScalar(@constructor.SPHERE_RADIUS / Math.abs(v[@_getFace(v)]))
