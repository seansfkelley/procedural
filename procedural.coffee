scene = new THREE.Scene
camera = new THREE.PerspectiveCamera 75, window.innerWidth / window.innerHeight, 0.1, 1000

renderer = new THREE.WebGLRenderer
renderer.setSize window.innerWidth, window.innerHeight

document.body.appendChild renderer.domElement

camera.position.z = 5

THREE.Vector3.prototype.toString = -> "<#{@x}, #{@y}, #{@z}>"

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

  console.log a, b, c

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

do ->
  material = new THREE.MeshBasicMaterial { color : 0x00ff00, wireframe : true }
  meshes = []

  for geometry in [
    # x-side
    tileSquare(new THREE.Vector3(-1, -1, 1), new THREE.Vector3(-1, 1, -1), new THREE.Vector3(-1, 0, 0), 5)
    tileSquare(new THREE.Vector3( 1, -1, 1), new THREE.Vector3( 1, 1, -1), new THREE.Vector3( 1, 0, 0), 5)

    # y-side
    tileSquare(new THREE.Vector3(-1,  1, -1), new THREE.Vector3(1,  1, 1), new THREE.Vector3(0,  1, 0), 5)
    tileSquare(new THREE.Vector3(-1, -1, -1), new THREE.Vector3(1, -1, 1), new THREE.Vector3(0, -1, 0), 5)

    # z-side
    tileSquare(new THREE.Vector3(-1, -1, -1), new THREE.Vector3(1, 1, -1), new THREE.Vector3(0, 0,  1), 5)
    tileSquare(new THREE.Vector3(-1, -1,  1), new THREE.Vector3(1, 1,  1), new THREE.Vector3(0, 0, -1), 5)
  ]

    for v in geometry.vertices
      v.setLength 1

    # TODO: Merge into one mesh, probably.
    mesh = new THREE.Mesh geometry, material
    scene.add mesh
    meshes.push mesh

  # Just wrap it in a closure so we don't assign this function to `window`.
  render = ->
    requestAnimationFrame render
    renderer.render scene, camera

    for mesh in meshes
      mesh.rotation.x += 0.005
      mesh.rotation.y += 0.015
      mesh.rotation.z += 0.020

  render()
