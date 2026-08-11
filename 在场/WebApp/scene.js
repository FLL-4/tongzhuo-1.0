function buildRain() {
  const layer = document.querySelector("#rain-layer");
  const fragment = document.createDocumentFragment();
  for (let index = 0; index < 70; index += 1) {
    const drop = document.createElement("i");
    drop.className = "rain-drop";
    drop.style.left = `${Math.random() * 110 - 5}%`;
    drop.style.setProperty("--drop-length", `${10 + Math.random() * 22}px`);
    drop.style.setProperty("--drop-speed", `${0.75 + Math.random() * 0.9}s`);
    drop.style.setProperty("--drop-delay", `${Math.random() * -4}s`);
    drop.style.opacity = (0.25 + Math.random() * 0.55).toFixed(2);
    fragment.appendChild(drop);
  }
  layer.appendChild(fragment);
}

function buildSteam(sources) {
  const layer = document.querySelector("#steam-layer");
  layer.replaceChildren();
  const fragment = document.createDocumentFragment();

  sources.forEach((source, sourceIndex) => {
    for (let index = 0; index < source.particleCount; index += 1) {
      const wisp = document.createElement("i");
      const direction = (index % 2 === 0 ? 1 : -1) * (4 + (index % 3) * 2);
      wisp.className = "steam-wisp";
      wisp.style.left = `${source.xPercent + (index % 3 - 1) * 0.35}%`;
      wisp.style.top = `${source.yPercent + (index % 2) * 0.7}%`;
      wisp.style.setProperty("--steam-drift", `${direction}px`);
      wisp.style.setProperty("--steam-drift-mid", `${direction * -0.45}px`);
      wisp.style.setProperty("--steam-delay", `${-(index * 0.72 + sourceIndex * 0.38)}s`);
      wisp.style.setProperty("--steam-speed", `${3.4 + (index % 3) * 0.45}s`);
      wisp.style.setProperty("--steam-opacity", String(source.opacity));
      fragment.appendChild(wisp);
    }
  });

  layer.appendChild(fragment);
}

document.addEventListener("DOMContentLoaded", () => {
  buildRain();

  const state = {
    sceneID: "rainy-study",
    imagePath: "./assets/scenes/rainy-study/together.png",
    imageAlt: "雨夜中，两个人在像素书房里安静同桌",
    weatherEffect: "rain",
    atmosphericEffect: "none",
    steamAnchors: [],
    weatherEffectsEnabled: true,
    presence: "focus",
  };
  let steamSignature = "";

  window.ZaichangScene = {
    render(payload = {}) {
      Object.assign(state, payload);
      const image = document.querySelector("#room-image");

      if (image.dataset.source !== state.imagePath) {
        const requestedSource = state.imagePath;
        image.dataset.source = requestedSource;
        image.style.opacity = "0";
        window.setTimeout(() => {
          if (image.dataset.source !== requestedSource) return;
          image.src = requestedSource;
          image.alt = state.imageAlt;
          image.style.opacity = "1";
        }, 220);
      } else {
        image.alt = state.imageAlt;
      }

      document.querySelector("#room-stage").dataset.state = state.presence;
      document.querySelector("#rain-layer").classList.toggle(
        "hidden",
        state.weatherEffect !== "rain" || !state.weatherEffectsEnabled
      );

      const nextSteamSignature = JSON.stringify(state.steamAnchors);
      if (nextSteamSignature !== steamSignature) {
        buildSteam(state.steamAnchors);
        steamSignature = nextSteamSignature;
      }
      document.querySelector("#steam-layer").classList.toggle(
        "hidden",
        state.atmosphericEffect !== "steam" || state.steamAnchors.length === 0
      );
    },
  };

  window.ZaichangScene.render(state);
});
