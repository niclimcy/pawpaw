// Ripple on the header links when pressed.
// No top-level consts: they'd clash with the inline script on index.html.
document.querySelectorAll(".nav a").forEach((link) => {
  link.addEventListener("pointerdown", (event) => {
    if (event.button !== 0) return;
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const rect = link.getBoundingClientRect();
    // Big enough to reach the farthest corner from the touch point.
    const radius = Math.hypot(
      Math.max(event.clientX - rect.left, rect.right - event.clientX),
      Math.max(event.clientY - rect.top, rect.bottom - event.clientY)
    );
    const ripple = document.createElement("span");
    ripple.className = "ripple";
    ripple.style.width = ripple.style.height = `${radius * 2}px`;
    ripple.style.left = `${event.clientX - rect.left - radius}px`;
    ripple.style.top = `${event.clientY - rect.top - radius}px`;
    ripple.addEventListener("animationend", () => ripple.remove());
    link.append(ripple);
  });
});
