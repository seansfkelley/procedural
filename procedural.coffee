scene = new THREE.Scene
camera = new THREE.PerspectiveCamera 45, window.innerWidth / window.innerHeight, 0.1, 1000

renderer = new THREE.WebGLRenderer
renderer.setSize window.innerWidth, window.innerHeight

# controls = new THREE.PointerLockControls camera
# scene.add controls.getObject()

# controls = new THREE.FlyControls camera
# controls.movementSpeed = 100
# controls.rollSpeed = Math.PI / 4
# controls.dragToLook = true

controls = new THREE.PointerLockFlyControls camera
controls.movementSpeed = 100
controls.rollSpeed = Math.PI / 4

setupPointerLock = ->
  if not 'pointerLockElement' of document
    throw new Error 'missing pointerLockElement'

  element = document.body

  pointerlockchange = (ev) ->
    controls.enabled = document.pointerLockElement == element

  pointerlockerror = (ev) ->
    debugger
    throw new Error 'pointerlockerror'

  document.addEventListener 'pointerlockchange', pointerlockchange, false
  document.addEventListener 'pointerlockerror',  pointerlockerror,  false

  $(document).on 'click', -> element.requestPointerLock()

setupPointerLock()

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

material = new THREE.MeshBasicMaterial { color : 0x00ff00, wireframe : true }
meshes = []

for geometry in [
  # x-side
  tileSquare(new THREE.Vector3(-1, -1, 1), new THREE.Vector3(-1, 1, -1), new THREE.Vector3(-1, 0, 0), 10)
  tileSquare(new THREE.Vector3( 1, -1, 1), new THREE.Vector3( 1, 1, -1), new THREE.Vector3( 1, 0, 0), 10)

  # y-side
  tileSquare(new THREE.Vector3(-1,  1, -1), new THREE.Vector3(1,  1, 1), new THREE.Vector3(0,  1, 0), 10)
  tileSquare(new THREE.Vector3(-1, -1, -1), new THREE.Vector3(1, -1, 1), new THREE.Vector3(0, -1, 0), 10)

  # z-side
  tileSquare(new THREE.Vector3(-1, -1, -1), new THREE.Vector3(1, 1, -1), new THREE.Vector3(0, 0,  1), 10)
  tileSquare(new THREE.Vector3(-1, -1,  1), new THREE.Vector3(1, 1,  1), new THREE.Vector3(0, 0, -1), 10)
]

  for v in geometry.vertices
    v.setLength 25

  # TODO: Merge into one mesh, probably.
  mesh = new THREE.Mesh geometry, material
  scene.add mesh
  meshes.push mesh

clock = new THREE.Clock
render = ->
  delta = clock.getDelta()

  controls.update delta

  requestAnimationFrame render
  renderer.render scene, camera

requestAnimationFrame render
