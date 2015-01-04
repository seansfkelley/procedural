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

class window.AdaptiveSphereMesh extends THREE.Mesh
  constructor : (material = null) ->
    g = new THREE.Geometry

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
    @_sphereFaceGeometries = [
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
    ].map ({ origin, face, direction }) ->
      normal = new THREE.Vector3
      normal[face] = direction
      target = origin.clone().negate().multiplyScalar(2).add(origin)
      target[face] = direction
      return tileSquare(origin, target, normal, 10)

    for faceGeometry in @_sphereFaceGeometries
      g.merge faceGeometry, faceGeometry.matrix

    # Discovered this myself. Others have the same issue:
    # http://blog.olav.it/post/44702519698/subclassing-three-js-objects-in-coffeescript
    THREE.Mesh.call this, g, material

    @toSphere()

  toSphere : =>
    for v in @geometry.vertices
      v.setLength 25
    @geometry.verticesNeedUpdate = true

  toCube : =>
    for v in @geometry.vertices
      face = @_getFace v
      v.multiplyScalar 25 / Math.abs(v[face])
    @geometry.verticesNeedUpdate = true

  _getFace : (v) ->
    [ x, y, z ] = v.toArray().map Math.abs
    if x >= y and x >= z
      return 'x'
    else if y >= x and y >= z
      return 'y'
    else if z >= x and z >= y
      return 'z'
    throw new Error 'math is hard'
