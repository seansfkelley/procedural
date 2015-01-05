AXIS_LENGTH = 5

addToScene = (scene, location = null) ->
  location ?= new THREE.Vector3

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
    size = new THREE.Vector3 0.1, 0.1, 0.1
    size[axis] = AXIS_LENGTH
    mesh = new THREE.Mesh(
      # Based on http://stackoverflow.com/a/14378462; need to have the null here for some reason.
      new (Function.prototype.bind.apply(THREE.BoxGeometry, [ null ].concat size.toArray()))
      new THREE.MeshBasicMaterial { color }
    )
    mesh.position[axis] = AXIS_LENGTH / 2
    mesh.position.add location
    scene.add mesh

  return # loop

window.Axes = { addToScene }
