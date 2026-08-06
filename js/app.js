(function () {
  "use strict";

  var PARTICLE_COUNT = 500;
  var WORLD_SIZE = 2000;
  var SWIPE_THRESHOLD = 80;
  var BASE_FALL_SPEED = -10;
  var particles = [];
  var touchStartX = null;
  var animationFrame = null;
  var camera;
  var scene;
  var renderer;

  function createParticles(material) {
    for (var i = 0; i < PARTICLE_COUNT; i += 1) {
      var particle = new Particle3D(material);
      particle.position.x = Math.random() * WORLD_SIZE - WORLD_SIZE / 2;
      particle.position.y = Math.random() * WORLD_SIZE - WORLD_SIZE / 2;
      particle.position.z = Math.random() * WORLD_SIZE - WORLD_SIZE / 2;
      particle.scale.x = particle.scale.y = 1;
      scene.add(particle);
      particles.push(particle);
    }
  }

  function setVelocity(speedX) {
    particles.forEach(function (particle) {
      particle.velocity = new THREE.Vector3(speedX, BASE_FALL_SPEED, 0);
    });
  }

  function applySwipe(direction) {
    var speedX = 25 * direction;
    setVelocity(speedX);

    var easing = window.setInterval(function () {
      speedX *= 0.8;
      if (Math.abs(speedX) <= 1.5) {
        speedX = 0;
        window.clearInterval(easing);
      }
      setVelocity(speedX);
    }, 100);
  }

  function onTouchStart(event) {
    if (event.touches.length === 1) {
      touchStartX = event.touches[0].pageX;
    }
  }

  function onTouchEnd(event) {
    if (touchStartX === null || event.changedTouches.length === 0) return;
    var distance = event.changedTouches[0].pageX - touchStartX;
    touchStartX = null;
    if (Math.abs(distance) >= SWIPE_THRESHOLD) applySwipe(distance > 0 ? 1 : -1);
  }

  function wrapPosition(position) {
    var half = WORLD_SIZE / 2;
    if (position.y < -half) position.y += WORLD_SIZE;
    if (position.x > half) position.x -= WORLD_SIZE;
    else if (position.x < -half) position.x += WORLD_SIZE;
    if (position.z > half) position.z -= WORLD_SIZE;
    else if (position.z < -half) position.z += WORLD_SIZE;
  }

  function render() {
    particles.forEach(function (particle) {
      particle.updatePhysics();
      wrapPosition(particle.position);
    });
    camera.lookAt(scene.position);
    renderer.render(scene, camera);
    animationFrame = window.requestAnimationFrame(render);
  }

  function resize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  }

  function init() {
    var container = document.getElementById("snow-scene");
    if (!container || !window.THREE || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 1, 10000);
    camera.position.z = 1000;
    scene = new THREE.Scene();
    scene.add(camera);
    renderer = new THREE.CanvasRenderer();
    renderer.setSize(window.innerWidth, window.innerHeight);
    container.appendChild(renderer.domElement);

    var particleImage = new Image();
    particleImage.onload = function () {
      createParticles(new THREE.ParticleBasicMaterial({ map: new THREE.Texture(particleImage) }));
      render();
    };
    particleImage.src = "images/funny.png";

    window.addEventListener("resize", resize);
    container.addEventListener("touchstart", onTouchStart, { passive: true });
    container.addEventListener("touchend", onTouchEnd, { passive: true });
  }

  window.addEventListener("DOMContentLoaded", init);
  window.addEventListener("pagehide", function () {
    if (animationFrame !== null) window.cancelAnimationFrame(animationFrame);
  });
}());
