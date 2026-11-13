(() => {
  const slides = Array.from(document.querySelectorAll(".slide"));
  const total = slides.length;
  const counter = document.getElementById("progress");
  const prevBtn = document.getElementById("prev");
  const nextBtn = document.getElementById("next");

  function indexFromHash() {
    const m = /^#s(\d+)$/.exec(location.hash);
    if (!m) return 0;
    const n = Number(m[1]) - 1;
    return Number.isFinite(n) ? Math.min(Math.max(n, 0), total - 1) : 0;
  }

  let index = indexFromHash();

  function render() {
    slides.forEach((el, i) => el.classList.toggle("active", i === index));
    if (counter) counter.textContent = `${index + 1} / ${total}`;
    if (prevBtn) prevBtn.disabled = index === 0;
    if (nextBtn) nextBtn.disabled = index === total - 1;
    const hash = `#s${index + 1}`;
    if (location.hash !== hash) {
      history.replaceState(null, "", hash);
    }
  }

  function go(delta) {
    index = Math.min(Math.max(index + delta, 0), total - 1);
    render();
  }

  prevBtn?.addEventListener("click", () => go(-1));
  nextBtn?.addEventListener("click", () => go(1));

  document.addEventListener("keydown", (e) => {
    if (["ArrowRight", "ArrowDown", "PageDown", " "].includes(e.key)) {
      e.preventDefault();
      go(1);
    } else if (["ArrowLeft", "ArrowUp", "PageUp", "Backspace"].includes(e.key)) {
      e.preventDefault();
      go(-1);
    } else if (e.key === "Home") {
      e.preventDefault();
      index = 0;
      render();
    } else if (e.key === "End") {
      e.preventDefault();
      index = total - 1;
      render();
    }
  });

  window.addEventListener("hashchange", () => {
    index = indexFromHash();
    render();
  });

  document.querySelector(".deck")?.addEventListener("click", (e) => {
    if (e.target.closest("button, a, .nav")) return;
    const mid = window.innerWidth / 2;
    go(e.clientX >= mid ? 1 : -1);
  });

  render();
})();
