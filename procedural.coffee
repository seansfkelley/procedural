scene = new THREE.Scene
camera = new THREE.PerspectiveCamera 45, window.innerWidth / window.innerHeight, 0.1, 1000

renderer = new THREE.WebGLRenderer
renderer.setSize window.innerWidth, window.innerHeight

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

sphere = new AdaptiveSphereMesh new THREE.MeshBasicMaterial { color : 0x00ff00, wireframe : true }
scene.add sphere

sphere.toSphere()

setInterval sphere.toCube, 5000
setTimeout (-> setInterval sphere.toSphere, 5000), 2500

AXIS_LENGTH = 5

for { color, axis } in [
  color : 0xff0000
  axis  : 'x'
,
  color : 0x00ff00
  axis  : 'y'
,
  color : 0x0000ff
  axis  : 'z'
]
  size = new THREE.Vector3 0.5, 0.5, 0.5
  size[axis] = AXIS_LENGTH
  mesh = new THREE.Mesh(
    # Based on http://stackoverflow.com/a/14378462; need to have the null here for some reason.
    new (Function.prototype.bind.apply(THREE.BoxGeometry, [ null ].concat size.toArray()))
    new THREE.MeshBasicMaterial { color }
  )
  mesh.position[axis] = AXIS_LENGTH / 2
  scene.add mesh

clock = new THREE.Clock
render = ->
  delta = clock.getDelta()

  controls.update delta

  requestAnimationFrame render
  renderer.render scene, camera

requestAnimationFrame render
