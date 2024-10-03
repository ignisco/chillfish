class Ripple {
  PVector pos;  // Position of the ripple
  float radius;  // Current radius of the ripple
  float opacity;  // Current opacity of the ripple

  Ripple(PVector pos) {
    this.pos = pos.copy();  // Copy the position to avoid reference issues
    this.radius = 0.5;  // Initial radius of the ripple
    this.opacity = 120;  // Initial opacity of the ripple
  }

  // Update the ripple (increase size and reduce opacity)
  void update() {
    radius += 1;  // Increase the radius over time
    opacity -= 1.8;  // Reduce the opacity to fade out
  }

  // Display the ripple
  void display() {
    noFill();
    stroke(255, 255, 255, opacity);  // White color with decreasing opacity
    strokeWeight(2);
    ellipse(pos.x, pos.y, radius * 2, radius * 2);  // Draw an expanding circle
  }

  // Check if the ripple is still visible (opacity > 0)
  boolean isVisible() {
    return opacity > 0;
  }
}
