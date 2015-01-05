# ----- SETUP GLOBALS -----

scene = new THREE.Scene
camera = new THREE.PerspectiveCamera 45, window.innerWidth / window.innerHeight, 0.1, 1000

renderer = new THREE.WebGLRenderer
renderer.setSize window.innerWidth, window.innerHeight
document.body.appendChild renderer.domElement

# ----- SETUP CONTROLS -----

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

# ----- SETUP SCENE CONTENTS -----

# AXES
Axes.addToScene scene

# SPHERE
sphere = new AdaptiveSphereMesh new THREE.MeshBasicMaterial { color : 0x00ff00, wireframe : true }
scene.add sphere

sphere.toSphere()

setInterval sphere.toCube, 5000
setTimeout (-> setInterval sphere.toSphere, 5000), 2500

# INDICATORS
sphereIndicator = new THREE.Mesh(
  new THREE.SphereGeometry 1
  new THREE.MeshBasicMaterial { color : 0xff0000, wireframe : true }
)

cubeIndicator = new THREE.Mesh(
  new THREE.BoxGeometry 1, 1, 1
  new THREE.MeshBasicMaterial { color : 0x0000ff, wireframe : true }
)

scene.add sphereIndicator, cubeIndicator

# ----- MAIN LOOP -----

clock = new THREE.Clock
render = ->
  delta = clock.getDelta()

  controls.update delta

  sphereIndicator.position.copy sphere.projectOntoSphere(camera.position)
  cubeIndicator.position.copy sphere.projectOntoCube(camera.position)

  requestAnimationFrame render
  renderer.render scene, camera

requestAnimationFrame render
