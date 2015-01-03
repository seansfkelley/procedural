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

scene.add new AdaptiveSphereMesh(new THREE.MeshBasicMaterial { color : 0x00ff00, wireframe : true })

clock = new THREE.Clock
render = ->
  delta = clock.getDelta()

  controls.update delta

  requestAnimationFrame render
  renderer.render scene, camera

requestAnimationFrame render
